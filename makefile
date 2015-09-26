SOURCE=src/dgplugin.sp
PROGRAM=dgplugin.smx
CC=sourcemod/scripting/spcomp


all: clean build

build:

	echo "Compiling $(SOURCE)"
	$(CC)  $(SOURCE)

clean:
	rm -f $(PROGRAM)
