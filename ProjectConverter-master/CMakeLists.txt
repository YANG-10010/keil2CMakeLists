# ===================================================================
# 交叉编译工具链设置 (Cross-Compilation Toolchain Setup)
# ===================================================================
cmake_minimum_required(VERSION {{ cmake.version }})

# 设定目标系统为 Generic，这告诉 CMake 不要添加任何特定操作系统的标志
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)

# 设定交叉编译器路径 (由 python 脚本传入)
set(TOOLCHAIN_PATH "{{ cmake.toolchain_path | replace('\\', '/') }}")

# 定义交叉编译工具链中的各个工具
set(CMAKE_C_COMPILER "${TOOLCHAIN_PATH}/arm-none-eabi-gcc.exe")
set(CMAKE_CXX_COMPILER "${TOOLCHAIN_PATH}/arm-none-eabi-g++.exe")
set(CMAKE_ASM_COMPILER "${TOOLCHAIN_PATH}/arm-none-eabi-gcc.exe")
set(CMAKE_AR "${TOOLCHAIN_PATH}/arm-none-eabi-ar.exe")
set(CMAKE_OBJCOPY "${TOOLCHAIN_PATH}/arm-none-eabi-objcopy.exe")
set(CMAKE_OBJDUMP "${TOOLCHAIN_PATH}/arm-none-eabi-objdump.exe")
set(CMAKE_SIZE "${TOOLCHAIN_PATH}/arm-none-eabi-size.exe")

# 设定编译器初始标志
# 针对STM32F103RCT6，CPU是Cortex-M3。此设置由python脚本根据芯片型号自动生成
set(CMAKE_C_FLAGS_INIT "{{ cmake.core_flag }} -mthumb" CACHE INTERNAL "Initial C compiler flags")
set(CMAKE_CXX_FLAGS_INIT "{{ cmake.core_flag }} -mthumb" CACHE INTERNAL "Initial CXX compiler flags")

# 这行是关键，阻止CMake在链接时寻找默认的系统库
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# ===================================================================
# 项目信息与语言 (Project Information & Languages)
# ===================================================================
project({{ cmake.project }})
enable_language(C)
enable_language(ASM)
{% if cmake.cxx == 'true' %}
enable_language(CXX)
{% endif %}

# 设定输出目录
set(EXECUTABLE_OUTPUT_PATH ${CMAKE_BINARY_DIR}/bin)
set(LIBRARY_OUTPUT_PATH ${CMAKE_BINARY_DIR}/lib)

# ===================================================================
# 编译与链接标志 (Compiler and Linker Flags)
# ===================================================================
# C 语言编译标志
set(CMAKE_C_FLAGS "{{ cmake.c_flags }}" CACHE INTERNAL "c compiler flags")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} {% for define in cmake.defines %} -D{{ define }} {% endfor %}")

# C++ 语言编译标志
set(CMAKE_CXX_FLAGS "{{ cmake.cxx_flags }}" CACHE INTERNAL "cxx compiler flags")

# 汇编语言编译标志
set(CMAKE_ASM_FLAGS "{{ cmake.asm_flags }}" CACHE INTERNAL "asm compiler flags")

# 链接器标志
set(CMAKE_EXE_LINKER_FLAGS "{{ cmake.linker_flags }}" CACHE INTERNAL "executable linker flags")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -T ${CMAKE_SOURCE_DIR}/{{ cmake.linker_script }} -L {{ cmake.linker_path }}")


# ===================================================================
# 头文件与源文件 (Includes and Sources)
# ===================================================================
# 添加头文件搜索路径
{% for inc in cmake.incs %}
include_directories({{ inc | replace('\\', '/') }})
{% endfor %}

# 为汇编文件设置特定编译标志
{% for as in cmake.ass %}
set_source_files_properties({{ as.path | replace('\\', '/') }} PROPERTIES COMPILE_FLAGS "-x assembler-with-cpp")
{% endfor %}

# 添加所有源文件
add_executable(${CMAKE_PROJECT_NAME}.elf
    {% for src in cmake.files %}{{ src.path | replace('\\', '/') }}
    {% endfor %}
)

# 链接外部库
target_link_libraries(${CMAKE_PROJECT_NAME}.elf {% for lib in cmake.libs %} {{ lib.name }} {% endfor %})

# ===================================================================
# 构建后操作 (Post-Build Commands)
# ===================================================================
# 生成 .bin 文件
add_custom_command(OUTPUT ${EXECUTABLE_OUTPUT_PATH}/${CMAKE_PROJECT_NAME}.bin
    COMMAND ${CMAKE_OBJCOPY} -Obinary ${CMAKE_PROJECT_NAME}.elf ${EXECUTABLE_OUTPUT_PATH}/${CMAKE_PROJECT_NAME}.bin
    DEPENDS ${CMAKE_PROJECT_NAME}.elf
    WORKING_DIRECTORY ${EXECUTABLE_OUTPUT_PATH}
    COMMENT "Generating .bin file"
)

# 生成 .hex 文件
add_custom_command(OUTPUT ${EXECUTABLE_OUTPUT_PATH}/${CMAKE_PROJECT_NAME}.hex
    COMMAND ${CMAKE_OBJCOPY} -Oihex ${CMAKE_PROJECT_NAME}.elf ${EXECUTABLE_OUTPUT_PATH}/${CMAKE_PROJECT_NAME}.hex
    DEPENDS ${CMAKE_PROJECT_NAME}.elf
    WORKING_DIRECTORY ${EXECUTABLE_OUTPUT_PATH}
    COMMENT "Generating .hex file"
)

# 创建一个自定义目标，以确保 .bin 和 .hex 文件总是被生成
add_custom_target(${CMAKE_PROJECT_NAME}_artifacts ALL
    DEPENDS
    ${EXECUTABLE_OUTPUT_PATH}/${CMAKE_PROJECT_NAME}.bin
    ${EXECUTABLE_OUTPUT_PATH}/${CMAKE_PROJECT_NAME}.hex
)

# 打印固件大小信息
add_custom_target(size ALL
    COMMAND ${CMAKE_SIZE} "${EXECUTABLE_OUTPUT_PATH}/${CMAKE_PROJECT_NAME}.elf"
    DEPENDS ${CMAKE_PROJECT_NAME}.elf
    COMMENT "Firmware Size:"
)

# 使用 st-link 烧录固件
add_custom_target(flash COMMAND st-flash write ${EXECUTABLE_OUTPUT_PATH}/${CMAKE_PROJECT_NAME}.bin 0x8000000)

# 清理所有生成的文件
add_custom_target(clean-all COMMAND rm -rf ${CMAKE_BINARY_DIR}/*)
