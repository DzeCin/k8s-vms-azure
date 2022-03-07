import ast
import sys

x = ast.literal_eval(sys.argv[1])
res = ''
for i in x:
    for j in i.keys():
        res += j + "," + i[j][1] + "," + i[j][0] + ' '

print(res.rstrip())
