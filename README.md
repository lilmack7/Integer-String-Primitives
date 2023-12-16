# Integer-String-Primitives

MASM assembly project designed to take 10 signed integer inputs as strings from user. Program verifies that each input fits in a 32 bit register and consists only of valid inputs (digits 0-9, + and - if first character).
If invalid, the input is thrown away and the user is reprompted. If valid, the string is converted to an actual integer via use of stirng primitives. These integers are then used to generate the truncated average and sum. The program then displays these values as well as showing the user's input numbers by converting them back from integers to strings via string primitives. The program also employs macros to cut down on line usage. 
