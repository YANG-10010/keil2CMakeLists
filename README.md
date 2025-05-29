# keil2CMakeLists

## 这是什么？

`keil2CMakeLists` 是一个基于 Python 的实用工具，用于将专有 IDE（如 ARM Keil MDK 和 IAR）的项目文件（`.uvprojx`, `.ewp`）自动转换为通用的 `CMakeLists.txt` 构建文件。

通过此工具，开发者可以将原有的嵌入式项目迁移到跨平台的 CMake + GCC 工具链上进行编译和管理，从而摆脱特定 IDE 的束缚，便于进行版本控制和持续集成（CI/CD）。

**本代码库是基于 [phodina/ProjectConverter](https://github.com/phodina/ProjectConverter) 的微调版本，添加了交叉编译相关功能，添加了 `keil2CmakeLists.bat` 可以自动执行复制、打开clon等任务。**

## 主要功能

* **项目转换**：自动解析 Keil `.uvprojx` 或 IAR `.ewp` 文件，提取关键项目信息，包括源文件、头文件路径和宏定义。
* **CMake 文件生成**：根据解析出的信息，生成一个用于 ARM-GCC 交叉编译的 `CMakeLists.txt` 文件。
* **预置构建目标**：生成的 `CMakeLists.txt` 中包含多个实用的预定义目标，例如：
    * `size`: 编译后显示固件大小。
    * `flash`: 使用 `st-flash` 烧录固件到目标设备（需已安装并配置好 `st-flash`）。
    * `clean-all`: 清理所有构建生成的文件。
* **自动化执行** 使用 `keil2CmakeLists.bat` 脚本可以做到自动复制需要的文件到当前文件夹下生成 `CMakeLists.txt` 并打开clion。

## 如何使用？

### 步骤 1: 环境准备

确保您的系统已安装 `python3`，并安装 `Jinja2` 依赖库。

```shell
pip install Jinja2
```

### 步骤 2: 配置工具链路径 **（重要）**

在使用前，**必须**在脚本中指定您的 ARM GCC 交叉编译工具链的路径。

1.  打开 `cmake.py` 文件。
2.  找到 `cmake['toolchain_path']` 变量。
3.  将其值修改为本地工具链 `bin` 目录的绝对路径。

```python
# 文件: cmake.py

# ...
        # ======================= 新增/修改部分 =======================
        # 在此处设置您的ARM GCC工具链的bin目录路径
        # 确保路径格式正确，例如在Windows上使用正斜杠'/'
        cmake['toolchain_path'] = 'C:/your/path/to/arm-gnu-toolchain-14.2.rel1-mingw-w64-x86_64-arm-none-eabi/bin'
        
        # 将CPU核心参数单独传递给模板
        cmake['core_flag'] = core
        # ==========================================================
# ...
```
4.  打开 `keil2CmakeLists.bat` 文件。
5.  找到 `SOURCE_PATH` 变量。
6.  将其值修改为ProjectConverter-master文件夹绝对路径。

```bat
# 文件: keil2CmakeLists.bat

# ...
        :: ##################################################################
        :: #                                                                #
        :: #  Path to the folder containing the tool files.                 #
        :: #  (Pre-filled with the path you provided)                       #
        :: #                                                                #
        :: ##################################################################
        set "SOURCE_PATH=D:\Software\Green\Convert\keil2CmakeLists\ProjectConverter-master"
# ...
```
### 步骤 3: 运行 `keil2CmakeLists.bat` 脚本
