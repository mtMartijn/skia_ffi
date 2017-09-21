CXX := clang++

BIN_DIR := .
SRC_DIR := .
OBJ_DIR := deps
SHADER_SRC_DIR := glsl
SHADER_OBJ_DIR := ../bin/spv

CXXFLAGS := -Wall -Wno-unknown-attributes -g -std=c++14 -I../skia/include/core -I../skia/include/config -I../skia/include/gpu -I../skia/include/utils
LIBS := `pkg-config --static --libs gl glfw3 libwebpdemux libwebpmux freetype2 fontconfig luajit` -lskia -lvulkan 
LDFLAGS := -Wl,-rpath=lib,-L. $(LIBS)

PRG_NAME := mt
PRG_SRCS := $(wildcard $(SRC_DIR)/*.cpp)
PRG_HEADERS := $(wildcard $(SRC_DIR)/*.h)
PRG_OBJS := $(PRG_SRCS:$(SRC_DIR)/%.cpp=$(OBJ_DIR)/%.o)
DEPS := $(PRG_OBJS:.o=.d)

SHADER_FLAGS := -g

FRAG_SRCS := $(wildcard $(SHADER_SRC_DIR)/*.frag)
VERT_SRCS := $(wildcard $(SHADER_SRC_DIR)/*.vert)
COMP_SRCS := $(wildcard $(SHADER_SRC_DIR)/*.comp)
FRAG_OBJ := $(FRAG_SRCS:$(SHADER_SRC_DIR)/%.frag=$(SHADER_OBJ_DIR)/%.frag.spv)
VERT_OBJ := $(VERT_SRCS:$(SHADER_SRC_DIR)/%.vert=$(SHADER_OBJ_DIR)/%.vert.spv)
COMP_OBJ := $(COMP_SRCS:$(SHADER_SRC_DIR)/%.comp=$(SHADER_OBJ_DIR)/%.comp.spv)

RM := rm -rf

PRG_PATH := $(BIN_DIR)/$(PRG_NAME)

.PHONY: all clean run shaders

all: $(PRG_PATH)
	
-include $(DEPS)

shaders: $(FRAG_OBJ) $(VERT_OBJ) $(COMP_OBJ)

$(SHADER_OBJ_DIR)/%.spv: $(SHADER_SRC_DIR)/%
	@mkdir -p $(SHADER_OBJ_DIR)
	glslc $(SHADER_FLAGS) $< -o $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cpp
	@mkdir -p $(OBJ_DIR)
	$(CXX) $(CXXFLAGS) -c $< -MMD -o $@ 

$(PRG_PATH): $(PRG_OBJS)
	$(CXX) $^ $(LDFLAGS) -o $@
	@echo "==== Success! ===="

run:
	@cd $(BIN_DIR) && ./$(PRG_NAME)

clean:
	-$(RM) $(PRG_PATH) 
	-$(RM) $(OBJ_DIR)

