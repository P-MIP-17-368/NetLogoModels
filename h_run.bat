set d1="%cd%"
set ep="C:\Users\milibaru\OneDrive\darbas\MII projektas\Experiments\%2"
mkdir %ep%
copy Model_v3.nlogo %ep%
cd %ep%
"C:\Program Files\NetLogo 6.0.4\netlogo-headless.bat" --model Model_v3.nlogo --experiment %1 --table table.csv --spreadsheet spreadsheet.csv  >> result.txt
cd %d1%
