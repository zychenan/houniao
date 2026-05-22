# 后鸟 (Houniao)

后鸟——数据跟着人走，AI 替你分忧。

跨设备的墙，后鸟帮你打通。手机上复制的文字、收到的短信、存着的文件，自动出现在你的电脑和平板上——不管在同一张桌子，还是相隔两个城市。

它是三层结构的：
- **底座**：分布式同步引擎。设备间 P2P 直连 + 服务端兜底，数据本地优先，断网不断用。`[核心通路已通，P2P 与 C 模式待实现]`
- **中层**：信息枢纽。剪贴板流转、短信同步、大文件跨设备存取，数据自动跟随人。`[剪贴板可用，其余待实现]`
- **上层**：AI 决策中心。AI 读你的数据，自动分析、排行程、管家居——从"数据跟人走"到"AI 替人想"。`[规划中]`

不靠云，不付费，跑在你自己的设备上。

## 已实现

- 纯文字跨设备剪贴板实时同步（Android + Windows）
- Go 服务端 WebSocket 中转，局域网 + Tailscale 虚拟局域网互通
- mDNS 局域网自动发现服务端
- 断线补拉，网络恢复自动补齐缺失数据
- 数据本地优先——断网不停机

## 朝向

- 笔记、日历、待办模块化接入
- LAN P2P 直连（设备间不经过服务端）
- 设备本地 API，AI 智能体直连

## 快速开始

### 环境

- Go 1.25+
- Flutter 3.29+
- SQLite

### 编译

```bash
# 服务端
cd server && go build -o houniao-server ./cmd

# Windows 客户端
cd client && flutter build windows

# Android APK
cd client && flutter build apk --debug
```

### 运行

```bash
# 启动服务端
./server/houniao-server

# 启动客户端（Windows）
./client/build/windows/x64/runner/Debug/houniao.exe

# 安装到手机
adb install -r client/build/app/outputs/flutter-apk/app-debug.apk
```

## 目录

```
server/          Go 服务端
client/          Flutter 客户端
```
