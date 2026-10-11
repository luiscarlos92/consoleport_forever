from pathlib import Path
root=Path(r'C:\Program Files (x86)\World of Warcraft\_retail_')
source=(root/'Interface/AddOns/ConsolePort/Libs/External/LibActionButton-1.0/LibActionButton-1.0.lua').read_text(encoding='utf8')
start=source.index('function Update(self)')
end=source.index('function Generic:UpdateLocal()',start)
(Path(__file__).resolve().parent/'evidence/lab-update.lua').write_text(source[start:end],encoding='utf8')
