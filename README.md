# NetKeeperHelper
Linux端自动从安卓手机获取闪讯密码并连接闪讯

## 前提条件

具有wifi：供电脑和手机获取密码时通信使用

### Linux端

使用NetworkManager管理网络

(在manjaro kde桌面测试通过)

### Android端

使用配套闪讯服务端

详见 [NetKeeperServer](https://github.com/BeckXuan/NetKeeperServer)

## 脚本说明

该脚本默认后台常驻，建议设置为开机启动

当检测到连接到指定wifi，且网线接入时尝试连接Netkeeper

且当NetKeeper断开时自动重新连接

若本地存储的密码过期，则向手机端请求闪讯密码

不断尝试，直到连接上闪讯

## 参数配置说明

请对应配置NetKeeperHelper.sh中标有注释的参数

## 鸣谢

getPIN.py修改自miao1007的[Openwrt-NetKeeper](https://github.com/miao1007/Openwrt-NetKeeper)

## 开源协议

[Apache-2.0 License](https://github.com/BeckXuan/NetKeeperServer/blob/main/LICENSE)

