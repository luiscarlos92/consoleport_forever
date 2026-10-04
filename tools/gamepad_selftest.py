import ctypes,gc,json,subprocess,sys,time
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
from repository_paths import ROOT,output
base=ROOT/'scratch/controller-emulation'
sys.path.insert(0,str(base/'client'))
def require_game_closed():
    result=subprocess.check_output(['powershell','-NoProfile','-Command',"$cpfWowCount = @(Get-Process Wow,WowB,WowT -ErrorAction SilentlyContinue).Count; Write-Output $cpfWowCount"],text=True)
    assert int(result.strip())==0,'Stop: WoW must be closed for this OS-only controller self-test.'
require_game_closed()
import vgamepad as vg
from vgamepad.win import vigem_client as client
from vgamepad.win.virtual_gamepad import check_err
class Gamepad(ctypes.Structure):
    _fields_=[('buttons',ctypes.c_uint16),('lt',ctypes.c_uint8),('rt',ctypes.c_uint8),('lx',ctypes.c_int16),('ly',ctypes.c_int16),('rx',ctypes.c_int16),('ry',ctypes.c_int16)]
class State(ctypes.Structure):
    _fields_=[('packet',ctypes.c_uint32),('gamepad',Gamepad)]
get_state=ctypes.WinDLL('xinput1_4.dll').XInputGetState
get_state.argtypes=[ctypes.c_uint32,ctypes.POINTER(State)]
get_state.restype=ctypes.c_uint32
def state(index):
    value=State()
    error=get_state(index,ctypes.byref(value))
    return {'error':error} if error else {name:getattr(value.gamepad,name) for name,_ in Gamepad._fields_}
def user_index(pad):
    index=ctypes.c_uint32()
    check_err(client.vigem_target_x360_get_user_index(pad._busp,pad._devicep,ctypes.byref(index)))
    return index.value
def new_index(before):
    end=time.monotonic()+3
    while time.monotonic()<end:
        candidates=[i for i in range(4) if i not in before and 'error' not in state(i)]
        if len(candidates)==1:return candidates[0]
        time.sleep(.02)
    raise AssertionError('No unique newly connected XInput slot; do not use an existing controller index.')
def identify_report(pad):
    marker={**neutral,'buttons':int(vg.XUSB_BUTTON.XUSB_GAMEPAD_X),'lt':73,'rt':151,'lx':12345,'ly':-23456,'rx':7890,'ry':-15678}
    pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_X)
    pad.left_trigger(73);pad.right_trigger(151)
    pad.left_joystick(12345,-23456);pad.right_joystick(7890,-15678)
    end=time.monotonic()+3
    while time.monotonic()<end:
        pad.update()
        candidates=[i for i in range(4) if state(i)==marker]
        if len(candidates)==1:
            pad.reset();pad.update()
            return candidates[0]
        time.sleep(.02)
    raise AssertionError({'noUniqueControllerReport':True,'allSlots':[state(i) for i in range(4)]})
def wait_state(index,expected):
    end=time.monotonic()+3
    while time.monotonic()<end:
        actual=state(index)
        if actual==expected:return actual
        time.sleep(.02)
    raise AssertionError({'index':index,'expected':expected,'actual':actual,'allSlots':[state(i) for i in range(4)]})
neutral=dict(buttons=0,lt=0,rt=0,lx=0,ly=0,rx=0,ry=0)
checks=[]
pad=None
before={i for i in range(4) if 'error' not in state(i)}
try:
    pad=vg.VX360Gamepad()
    index=identify_report(pad)
    checks.append({'name':'connected-neutral','index':index,'busReportedIndex':user_index(pad),'osReadback':wait_state(index,neutral)})
    require_game_closed()
    for button in vg.XUSB_BUTTON:
        if button==vg.XUSB_BUTTON.XUSB_GAMEPAD_GUIDE:continue
        pad.press_button(button);pad.update()
        checks.append({'name':button.name,'osReadback':wait_state(index,{**neutral,'buttons':int(button)})})
        pad.reset();pad.update();wait_state(index,neutral)
    bits=int(vg.XUSB_BUTTON.XUSB_GAMEPAD_A)|int(vg.XUSB_BUTTON.XUSB_GAMEPAD_LEFT_SHOULDER)|int(vg.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_UP)
    pad.press_button(bits)
    pad.left_trigger(255);pad.right_trigger(128)
    pad.left_joystick(16384,-24576);pad.right_joystick(8192,32767)
    pad.update()
    expected=dict(buttons=bits,lt=255,rt=128,lx=16384,ly=-24576,rx=8192,ry=32767)
    checks.append({'name':'buttons-triggers-axes','osReadback':wait_state(index,expected)})
    started=time.monotonic()
    time.sleep(.55)
    checks.append({'name':'held-report','elapsedSeconds':round(time.monotonic()-started,3),'osReadback':wait_state(index,expected)})
    pad.reset();pad.update()
    checks.append({'name':'released-neutral','osReadback':wait_state(index,neutral)})
finally:
    if pad is not None:pad.reset();pad.update()
    pad=None;gc.collect()
checks.append({'name':'disconnected','osReadback':wait_state(index,{'error':1167})})
require_game_closed()
pad=vg.VX360Gamepad()
try:
    index=identify_report(pad)
    checks.append({'name':'reconnected-neutral','osReadback':wait_state(index,neutral)})
finally:
    pad.reset();pad.update();pad=None;gc.collect()
require_game_closed()
pad=vg.VDS4Gamepad()
try:
    checks.append({'name':'dualshock4-connected-neutral','vendor':pad.get_vid(),'product':pad.get_pid(),'type':int(pad.get_type()),'attached':bool(client.vigem_target_is_attached(pad._devicep)),'specialButtonsAvailable':['PS','touchpad'],'osButtonReadbackTested':False})
finally:
    pad.reset();pad.update();pad=None;gc.collect()
record={'scope':'OS-level virtual gamepad self-test; WoW closed; no Retail acceptance inferred','checks':checks,'driverInstalledOrUpdated':False,'liveWtfEdited':False}
output(base/'selftest.json').write_text(json.dumps(record,indent=2),encoding='utf-8')
print(json.dumps(record,indent=2))
