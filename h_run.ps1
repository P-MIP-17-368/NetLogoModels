$ep="C:\Users\milibaru\OneDrive\darbas\MII projektas\Experiments\0812-" + $args[1]
mkdir $ep
copy Model_v3.nlogo $ep
cd %ep%
"C:\Program Files\NetLogo 6.0.4\netlogo-headless.bat" --model Model_v3.nlogo --experiment $args[0] --table table.csv --spreadsheet spreadsheet.csv  >> result.txt