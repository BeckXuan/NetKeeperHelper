#!/usr/bin/python3
import time
import hashlib
import sys

def get_PIN(username):
    # 以下为杭州地区对应的参数
    RADIUS = 'singlenet01'
    PREFIX0 = '\r'
    PREFIX1 = '\n'

    timenow = int(time.time())
    timedivbyfive = timenow // 5
    timeByte = [timedivbyfive >> (8 * (3 - i)) & 0xFF for i in range(4)]
    beforeMD5 = timeByte
    beforeMD5 += list(map(ord, username[:username.index('@')]))
    beforeMD5 += list(map(ord, RADIUS))
    m = hashlib.md5()
    m.update(bytes(beforeMD5[:len(RADIUS)+16]))
    afterMD5 = m.hexdigest()
    MD501 = afterMD5[0:2]

    temp = []
    for i in range(32):
        t = (31 - i) // 8
        temp.append(timeByte[t] & 1)
        timeByte[t] >>= 1

    timeHash = []
    for i in range(4):
        timeHash.append(temp[i] * 128 + temp[4 + i] * 64 + temp[8 + i]
                        * 32 + temp[12 + i] * 16 + temp[16 + i] * 8 + temp[20 + i]
                        * 4 + temp[24 + i] * 2 + temp[28 + i])

    temp[1] = (timeHash[0] & 3) << 4
    temp[0] = (timeHash[0] >> 2) & 0x3F
    temp[2] = (timeHash[1] & 0xF) << 2
    temp[1] = (timeHash[1] >> 4 & 0xF) + temp[1]
    temp[3] = timeHash[2] & 0x3F
    temp[2] = ((timeHash[2] >> 6) & 0x3) + temp[2]
    temp[5] = (timeHash[3] & 3) << 4
    temp[4] = (timeHash[3] >> 2) & 0x3F

    PIN27 = []
    for i in range(6):
        PIN27.append(temp[i] + 0x20)
        if PIN27[i] >= 0x40:
            PIN27[i] += 1

    PIN = PREFIX0 + PREFIX1 + ''.join(map(chr, PIN27)) + MD501 + username
    return PIN

if __name__ == '__main__':
    if len(sys.argv) <= 1:
        print("Please input your username!")
        exit(1)
    username = sys.argv[1]
    #print(username)
    print(get_PIN(username))
