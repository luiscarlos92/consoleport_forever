"""Local VIIPER V5 DualSense input; explicit live mode, foreground guard, bounded holds.

Pinned contract: hbashton/VIIPER v0.1.9-rc4.6.6, device/dualsense/state.go
and ds_handler.go. Does not install drivers, select presets, or edit live WTF.
"""
import ctypes
import json
import math
import socket
import struct
import sys
import threading
import time
import zlib
from datetime import datetime, timezone
from pathlib import Path
from repository_paths import ROOT, output

ADDRESS = ('127.0.0.1', 3242)
BUTTONS = dict(square=0x10, cross=0x20, circle=0x40, triangle=0x80,
               l1=0x100, r1=0x200, create=0x1000, options=0x2000,
               l3=0x4000, r3=0x8000, ps=0x10000, touchpad=0x20000,
               mic=0x40000)
DPAD = {'none': 0, 'up': 1, 'down': 2, 'left': 4, 'right': 8,
        'up-left': 5, 'up-right': 9, 'down-left': 6, 'down-right': 10}


def scalar(value, low, high):
    value = float(value)
    if not math.isfinite(value) or not low <= value <= high:
        raise ValueError('Axis outside permitted finite range')
    return value


def payload(command):
    selected = command.get('buttons', [])
    if not isinstance(selected, list) or any(b not in BUTTONS for b in selected):
        raise ValueError('Unknown button')
    direction = command.get('dpad', 'none')
    if direction not in DPAD:
        raise ValueError('Unknown D-pad direction')
    sticks = command.get('left', [0, 0]) + command.get('right', [0, 0])
    if len(sticks) != 4:
        raise ValueError('Expected two axes per stick')
    axes = [round(scalar(v, -1, 1) * 127) for v in sticks]
    lt = round(scalar(command.get('lt', 0), 0, 1) * 255)
    rt = round(scalar(command.get('rt', 0), 0, 1) * 255)
    buttons = 0
    for name in selected:
        buttons |= BUTTONS[name]
    if lt > 76:
        buttons |= 0x400
    if rt > 76:
        buttons |= 0x800
    state = bytearray(33)
    struct.pack_into('<bbbbIBBB', state, 0, *axes, buttons, DPAD[direction], lt, rt)
    state[15] = state[20] = 0x80  # inactive touch contacts, never phantom touches
    struct.pack_into('<h', state, 31, -8192)  # upstream resting -1g
    return bytes(state)


def frame(state, sequence):
    if len(state) != 33:
        raise ValueError('Expected exactly 33 input bytes')
    fields = struct.pack('<BBHI', 5, 1, len(state), sequence)
    return b'VPCM' + fields + struct.pack('<I', zlib.crc32(fields + state)) + state


def request(path, data=None):
    message = path + ('' if data is None else ' ' + str(data))
    with socket.create_connection(ADDRESS, timeout=10) as connection:
        connection.sendall(message.encode() + b'\0')
        chunks = bytearray()
        while True:
            part = connection.recv(4096)
            if not part:
                break
            chunks.extend(part)
            if len(chunks) > 1024 * 1024:
                raise ValueError('Management response too large')
    result = json.loads(chunks)
    if result.get('status', 0) >= 400:
        raise RuntimeError(str(result))
    return result


def foreground_guard():
    user = ctypes.WinDLL('user32', use_last_error=True)
    kernel = ctypes.WinDLL('kernel32', use_last_error=True)
    user.GetForegroundWindow.restype = ctypes.c_void_p
    user.GetWindowThreadProcessId.argtypes = [ctypes.c_void_p, ctypes.POINTER(ctypes.c_uint32)]
    kernel.OpenProcess.argtypes = [ctypes.c_uint32, ctypes.c_bool, ctypes.c_uint32]
    kernel.OpenProcess.restype = ctypes.c_void_p
    kernel.QueryFullProcessImageNameW.argtypes = [ctypes.c_void_p, ctypes.c_uint32,
                                                ctypes.c_wchar_p, ctypes.POINTER(ctypes.c_uint32)]
    kernel.CloseHandle.argtypes = [ctypes.c_void_p]

    def check():
        pid = ctypes.c_uint32()
        user.GetWindowThreadProcessId(user.GetForegroundWindow(), ctypes.byref(pid))
        handle = kernel.OpenProcess(0x1000, False, pid.value)
        if not handle:
            return False
        try:
            length = ctypes.c_uint32(32768)
            name = ctypes.create_unicode_buffer(length.value)
            return bool(kernel.QueryFullProcessImageNameW(handle, 0, name, ctypes.byref(length))) and Path(name.value).name.lower() == 'wow.exe'
        finally:
            kernel.CloseHandle(handle)
    return check


class Controller:
    def __init__(self):
        self.lock = threading.RLock()
        self.stream = None
        self.bus = None
        self.device = None
        self.sequence = 0
        self.held = False
        self.deadline = 0
        self.closed = False
        self.foreground = foreground_guard()
        self.log = output(ROOT / 'scratch/controller-emulation/dualsense/live-events.jsonl')

    def emit(self, **value):
        value = dict(at=datetime.now(timezone.utc).isoformat(), **value)
        with self.log.open('a', encoding='utf-8') as stream:
            stream.write(json.dumps(value) + '\n')
        print(json.dumps(value), flush=True)

    def send(self, command):
        if not self.stream:
            raise ValueError('Controller disconnected')
        self.stream.sendall(frame(payload(command), self.sequence))
        self.sequence = (self.sequence + 1) & 0xffffffff

    def neutral(self):
        if self.stream:
            self.send({})
        self.held = False

    def feedback(self, stream):
        # Drain feedback without driving physical rumble/audio. Reject corrupt frames.
        def read(count):
            data = bytearray()
            while len(data) < count:
                part = stream.recv(count - len(data))
                if not part:
                    raise EOFError('Feedback disconnected')
                data.extend(part)
            return bytes(data)
        expected = None
        try:
            while True:
                header = read(16)
                version, kind, size, sequence, crc = struct.unpack('<BBHII', header[4:])
                if header[:4] != b'VPCM' or version != 5 or kind not in (0x81, 0x83):
                    raise ValueError('Unexpected feedback header')
                data = read(size)
                if zlib.crc32(header[4:12] + data) != crc or (expected is not None and sequence != expected):
                    raise ValueError('Feedback CRC/sequence mismatch')
                expected = (sequence + 1) & 0xffffffff
        except Exception as error:
            if self.stream is stream:
                self.emit(op='feedback-ended', reason=str(error))
                # Termination removes the input path immediately, no held state survives.
                stream.close()

    def connect(self):
        if self.stream:
            raise ValueError('Already connected')
        if not self.foreground():
            raise ValueError('Activate observed WoW window first')
        self.bus = request('bus/create')['busId']
        try:
            self.device = request(f'bus/{self.bus}/add', json.dumps({'type': 'dualsensegamepadv5'}))
            self.stream = socket.create_connection(ADDRESS, timeout=5)
            self.stream.sendall(f"bus/{self.bus}/{self.device['devId']}\0".encode())
            self.stream.settimeout(None)
            self.sequence = 0
            self.neutral()
            threading.Thread(target=self.feedback, args=(self.stream,), daemon=True).start()
            self.emit(op='connected', device=self.device, controller='DualSense USB V5')
        except Exception:
            self.disconnect()
            raise

    def disconnect(self):
        if self.stream:
            try:
                self.neutral()
            except OSError:
                pass
            stream, self.stream = self.stream, None
            stream.close()
        if self.bus is not None:
            try:
                request('bus/remove', self.bus)  # exclusively the newly created own bus
            except Exception as error:
                self.emit(op='cleanup-error', reason=str(error), ownedBus=self.bus)
            self.bus = self.device = None
        self.held = False

    def watchdog(self):
        while not self.closed:
            with self.lock:
                if self.held and (time.monotonic() >= self.deadline or not self.foreground()):
                    try:
                        self.neutral()
                        self.emit(op='watchdog-neutral', reason='focus loss or bounded hold elapsed')
                    except OSError:
                        self.disconnect()
            time.sleep(.05)

    def run(self):
        self.connect()
        threading.Thread(target=self.watchdog, daemon=True).start()
        try:
            for line in sys.stdin:
                try:
                    command = json.loads(line)
                    op = command.get('op', 'state')
                    with self.lock:
                        if op == 'quit':
                            break
                        if op == 'disconnect':
                            self.disconnect()
                        elif op == 'connect':
                            self.connect()
                        elif op == 'neutral':
                            self.neutral()
                        elif op == 'state':
                            if not self.foreground():
                                raise ValueError('WoW not foreground; no input sent')
                            duration = scalar(command.get('duration', .15), 0, 3)
                            self.send(command)
                            self.held = True
                            self.deadline = time.monotonic() + 10
                            # Release independent of foreground-check latency.
                            time.sleep(duration)
                            if command.get('release', True):
                                self.neutral()
                        else:
                            raise ValueError('Unknown operation')
                        self.emit(op=op, request=command, held=self.held)
                except Exception as error:
                    with self.lock:
                        try:
                            self.neutral()
                        except OSError:
                            self.disconnect()
                    self.emit(op='error', reason=str(error))
        finally:
            self.closed = True
            with self.lock:
                self.disconnect()
            self.emit(op='quit')


def contract_check():
    neutral = payload({})
    assert len(neutral) == 33 and neutral[15] == neutral[20] == 128
    assert struct.unpack_from('<h', neutral, 31)[0] == -8192
    chord = payload({'buttons': ['create'], 'rt': 1, 'left': [-1, 1], 'dpad': 'down-left'})
    assert chord[:4] == bytes.fromhex('817f0000')
    assert chord[4:11] == bytes.fromhex('001800000600ff')
    encoded = frame(chord, 37)
    assert encoded[:12] == bytes.fromhex('5650434d0501210025000000')
    # Independent bitwise IEEE CRC, not the frame encoder's zlib function.
    crc = 0xffffffff
    for byte in encoded[4:12] + encoded[16:]:
        crc ^= byte
        for _ in range(8):
            crc = (crc >> 1) ^ (0xedb88320 if crc & 1 else 0)
    assert struct.unpack_from('<I', encoded, 12)[0] == crc ^ 0xffffffff
    for bad in ({'lt': float('nan')}, {'left': [2, 0]}, {'buttons': ['bad']}, {'dpad': 'bad'}):
        try:
            payload(bad)
        except ValueError:
            continue
        raise AssertionError('Invalid input accepted')
    print('DualSense V5 packet contract checks passed; no OS/game pass claimed.')


if __name__ == '__main__':
    if sys.argv[1:] == ['--contract-check']:
        contract_check()
    elif sys.argv[1:] == ['--live']:
        Controller().run()
    else:
        raise SystemExit('Use --contract-check or explicitly --live')
