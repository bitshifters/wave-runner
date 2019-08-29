# -*- mode: makefile-gmake -*-
##########################################################################
##########################################################################

ifeq ($(OS),Windows_NT)

PYTHON?=python
BEEBASM?=beebasm
EXOMIZER3?=bin\exomizer
EXOMIZER2?=audio\exomizer

# don't need Mono on Windows.
MONO:=

else

PYTHON?=python
BEEBASM?=beebasm
EXOMIZER3?=exomizer3
EXOMIZER2?=exomizer2
MONO?=mono

endif

##########################################################################
##########################################################################

SHELLCMD:=$(PYTHON) bin/shellcmd.py
WRAP_EXOMIZER3:=$(PYTHON) bin/exomizer_wrapper.py --verbose --exomizer=$(EXOMIZER3)
INTERMEDIATE=./intermediate

PNG2BBC:=$(PYTHON) bin/png2bbc.py
PNG2BBC_DEPS:=bin/png2bbc.py bin/bbc.py bin/png.py

VGMCONVERTER:=$(PYTHON) audio/vgmconverter.py
VGMCONVERTER_DEPS:=audio/vgmconverter.py

##########################################################################
##########################################################################

# font stuff

FONT_EXTRACTOR:=./output/FontExtractor/Release/FontExtractor.exe
FONT_SOURCE_FOLDER:=./fonts
FONT_OUTPUT_FOLDER:=$(INTERMEDIATE)/font/razor14x14/images/
FONT_SOURCE_FILE:=$(FONT_SOURCE_FOLDER)/Charset_1Bitplan.PNG
FONT_GLYPHS_FILE:=$(FONT_SOURCE_FOLDER)/CharsetRazor.txt

##########################################################################
##########################################################################

# RasterGen stuff

RASTER_GEN:=./output/RasterGen/Release/RasterGen.exe
RASTER_GEN_INPUT_PATH:=$(FONT_OUTPUT_FOLDER)
RASTER_GEN_OUTPUT_PATH:=$(INTERMEDIATE)/font/razor14x14/code/

##########################################################################
##########################################################################

# ImageAnalyser stuff

IMAGE_ANALYSER:=./output/ImageAnalyser/Release/ImageAnalyser.exe
IMAGE_ANALYSER_INPUT_PATH:=./graphics
# The trailing slash in the following line is important because of how ImageAnalyser parses the output folder.
# TODO: Fix ImageAnalyser so this is not necessary
IMAGE_ANALYSER_OUTPUT_PATH:=$(INTERMEDIATE)/

##########################################################################
##########################################################################


.PHONY:build
build:
	$(SHELLCMD) mkdir $(INTERMEDIATE)

	$(MONO) $(FONT_EXTRACTOR) imagefile:$(FONT_SOURCE_FILE) origin:1,0 padding:2,1 tilecount:20,3,56 tilesize:14,14 glyphsfile:$(FONT_GLYPHS_FILE) inputfolder:$(FONT_SOURCE_FOLDER) outputfolder:$(FONT_OUTPUT_FOLDER)

	$(MONO) $(RASTER_GEN) inputfolder:$(RASTER_GEN_INPUT_PATH) glyphsfile:$(FONT_GLYPHS_FILE) outputfolder:$(RASTER_GEN_OUTPUT_PATH)

	$(MONO) $(IMAGE_ANALYSER) imagefile:bslogo_single inputfolder:$(IMAGE_ANALYSER_INPUT_PATH) outputfolder:$(IMAGE_ANALYSER_OUTPUT_PATH)
	
	$(MAKE) $(INTERMEDIATE)/bs-logo-uniquelines.exo
	$(MAKE) $(INTERMEDIATE)/start-and-end-lines.exo
	$(MAKE) $(INTERMEDIATE)/Presents.exo
	$(MAKE) $(INTERMEDIATE)/Presents2.exo
	$(MAKE) $(INTERMEDIATE)/Outro.exo
	$(MAKE) $(INTERMEDIATE)/Title01.exo
	$(MAKE) $(INTERMEDIATE)/Minx.exo
	$(MAKE) $(INTERMEDIATE)/Minx2b.exo
	$(MAKE) $(INTERMEDIATE)/Minx2c.exo
	$(MAKE) $(INTERMEDIATE)/BitShift1.exo
	$(MAKE) $(INTERMEDIATE)/BitShift2.exo
	$(MAKE) $(INTERMEDIATE)/BitShift2b.exo	
	$(MAKE) $(INTERMEDIATE)/WaveRunner.exo
	$(MAKE) $(INTERMEDIATE)/Goodbye.exo
	$(MAKE) $(INTERMEDIATE)/Black.exo
	
	$(MAKE) $(INTERMEDIATE)/MAIN.exo	

	$(MAKE) $(INTERMEDIATE)/blobs.exo
	$(MAKE) $(INTERMEDIATE)/cheq_full_4bpp.exo
	$(MAKE) $(INTERMEDIATE)/anuvverbubbla_8x8.exo
	$(MAKE) $(INTERMEDIATE)/test-grid-full.exo
	$(MAKE) $(INTERMEDIATE)/scroller5.exo
	$(MAKE) $(INTERMEDIATE)/prerendered.exo

	$(BEEBASM) -i main.6502 -di template.ssd -do BSNova19.ssd -v > $(INTERMEDIATE)/beebasm_output.txt

	@$(SHELLCMD) blank-line
	@$(SHELLCMD) sha1 BSNova19.ssd

##########################################################################
##########################################################################

.PHONY:clean
clean:
	$(SHELLCMD) rm-tree $(INTERMEDIATE)

##########################################################################
##########################################################################

$(INTERMEDIATE)/blobs.exo : ./bin/make_blobs.py $(PNG2BBC_DEPS) Makefile
	$(PYTHON) $<
	$(WRAP_EXOMIZER3) $(basename $@).dat@0x2000 $@ level -c -M256

$(INTERMEDIATE)/bs-logo-uniquelines.exo : ./intermediate/bslogo_singleuniquelines.png $(PNG2BBC_DEPS)  Makefile
	$(PNG2BBC) --quiet -o $(basename $@).dat $< 1
	$(WRAP_EXOMIZER3) $(basename $@).dat@0x3000 $@ level -c -M256
	
$(INTERMEDIATE)/start-and-end-lines.exo : ./graphics/StartAndEndLines.png $(PNG2BBC_DEPS)  Makefile
	$(PNG2BBC) --quiet -o $(basename $@).dat $< 1
	$(WRAP_EXOMIZER3) $(basename $@).dat@0x5080 $@ level -c -M256

$(INTERMEDIATE)/Title01.exo : ./graphics/Title01.png $(PNG2BBC_DEPS)  Makefile
	$(PNG2BBC) --quiet -o $(basename $@).dat $< 2
	$(WRAP_EXOMIZER3) $(basename $@).dat@0x3000 $@ level -c -M256	

$(INTERMEDIATE)/Presents.exo : ./graphics/Presents.png $(PNG2BBC_DEPS)  Makefile
	$(PNG2BBC) --quiet -o $(basename $@).dat $< 2
	$(WRAP_EXOMIZER3) $(basename $@).dat@0x3000 $@ level -c -M256	

$(INTERMEDIATE)/Presents2.exo : ./graphics/Presents2.png $(PNG2BBC_DEPS)  Makefile
	$(PNG2BBC) --quiet -o $(basename $@).dat $< 2
	$(WRAP_EXOMIZER3) $(basename $@).dat@0x3000 $@ level -c -M256

$(INTERMEDIATE)/Outro.exo : ./graphics/Outro.png $(PNG2BBC_DEPS)  Makefile
	$(PNG2BBC) --quiet -o $(basename $@).dat $< 2
	$(WRAP_EXOMIZER3) $(basename $@).dat@0x3000 $@ level -c -M256

$(INTERMEDIATE)/Minx.exo : ./graphics/Minx.png $(PNG2BBC_DEPS)  Makefile
	$(PNG2BBC) --quiet -o $(basename $@).dat --palette 7130 $< 1
	$(WRAP_EXOMIZER3) $(basename $@).dat@0x3000 $@ level -c -M256	

$(INTERMEDIATE)/Minx2c.exo : ./graphics/Minx2c.png $(PNG2BBC_DEPS)  Makefile
	$(PNG2BBC) --quiet -o $(basename $@).dat --palette 4120 $< 1
	$(WRAP_EXOMIZER3) $(basename $@).dat@0x3000 $@ level -c -M256

$(INTERMEDIATE)/Minx2b.exo : ./graphics/Minx2b.png $(PNG2BBC_DEPS)  Makefile
	$(PNG2BBC) --quiet -o $(basename $@).dat --palette 7120 $< 1
	$(WRAP_EXOMIZER3) $(basename $@).dat@0x3000 $@ level -c -M256

$(INTERMEDIATE)/BitShift1.exo : ./graphics/BitShift1.png $(PNG2BBC_DEPS)  Makefile
	$(PNG2BBC) --quiet -o $(basename $@).dat --palette 7240 $< 1
	$(WRAP_EXOMIZER3) $(basename $@).dat@0x3000 $@ level -c -M256

$(INTERMEDIATE)/BitShift2.exo : ./graphics/BitShift2.png $(PNG2BBC_DEPS)  Makefile
	$(PNG2BBC) --quiet -o $(basename $@).dat --palette 4120 $< 1
	$(WRAP_EXOMIZER3) $(basename $@).dat@0x3000 $@ level -c -M256	

$(INTERMEDIATE)/BitShift2b.exo : ./graphics/BitShift2b.png $(PNG2BBC_DEPS)  Makefile
	$(PNG2BBC) --quiet -o $(basename $@).dat --palette 4120 $< 1
	$(WRAP_EXOMIZER3) $(basename $@).dat@0x3000 $@ level -c -M256	

$(INTERMEDIATE)/WaveRunner.exo : ./graphics/WaveRunner.png $(PNG2BBC_DEPS)  Makefile
	$(PNG2BBC) --quiet -o $(basename $@).dat $< 2
	$(WRAP_EXOMIZER3) $(basename $@).dat@0x3000 $@ level -c -M256	

$(INTERMEDIATE)/Goodbye.exo : ./graphics/Goodbye.png $(PNG2BBC_DEPS)  Makefile
	$(PNG2BBC) --quiet -o $(basename $@).dat $< 2
	$(WRAP_EXOMIZER3) $(basename $@).dat@0x3000 $@ level -c -M256		

$(INTERMEDIATE)/Black.exo : ./graphics/Black.png $(PNG2BBC_DEPS)  Makefile
	$(PNG2BBC) --quiet -o $(basename $@).dat $< 2
	$(WRAP_EXOMIZER3) $(basename $@).dat@0x3000 $@ level -c -M256		
	
$(INTERMEDIATE)/test-grid-full.exo : ./graphics/TestGridFull.png $(PNG2BBC_DEPS)  Makefile
	$(PNG2BBC) --quiet -o $(basename $@).dat $< 1
	$(WRAP_EXOMIZER3) $(basename $@).dat@0x3000 $@ level -c -M256

$(INTERMEDIATE)/cheq_full_4bpp.exo : ./bin/make_cheq.py $(PNG2BBC_DEPS) Makefile
	$(PYTHON) $<
	$(WRAP_EXOMIZER3) $(basename $@).dat@0x3000 $@ level -c -M256

$(INTERMEDIATE)/anuvverbubbla_8x8.exo : ./bin/make_cheq_font.py ./fonts/anuvverbubbla_8x8.png $(PNG2BBC_DEPS) Makefile
	$(PYTHON) $<
	$(WRAP_EXOMIZER3) $(basename $@).dat@0x2000 $@ level -c -M256

$(INTERMEDIATE)/scroller5.exo : ./graphics/scroller5.dat $(PNG2BBC_DEPS) Makefile
	$(WRAP_EXOMIZER3) $<@0x3000 $@ level -c -M256

$(INTERMEDIATE)/prerendered.exo : ./bin/make_prerendered.py $(PNG2BBC_DEPS) Makefile
	$(PYTHON) $<
	$(WRAP_EXOMIZER3) $(basename $@).dat@0x2000 $@ level -c -M256

##########################################################################
##########################################################################

$(INTERMEDIATE)/%.exo : ./audio/music/vgm/%.vgm $(VGMCONVERTER_DEPS)
	$(VGMCONVERTER) "$<" -n -t bbc -q 50 -r "$(basename $@).raw" -o "$(basename $@).bbc.vgm" > "$(basename $@).process.txt"
	$(EXOMIZER2) raw -c -m 3328 "$(basename $@).raw" -o "$@" >> "$(basename $@).process.txt"

##########################################################################
##########################################################################

# Stuff for Tom's laptop

ifeq ($(OS),Windows_NT)
TRANSFER:=Z:/
else
TRANSFER:=$(HOME)/transfer/
endif

# .PHONY:tomx
# tomx:
#	$(SHELLCMD) copy-file intermediate/beebasm_output.txt $(TRANSFER)
#	$(SHELLCMD) copy-file BSNova19.ssd $(TRANSFER)
#	$(SHELLCMD) rm-tree $(TRANSFER)BSNova19
#	$(SHELLCMD) mkdir $(TRANSFERBSNova19
#	$(PYTHON) $(HOME)/beeb/bin/ssd_extract.py BSNova19.ssd -o $(TRANSFER)BSNova19

.PHONY:tom_beeblink
tom_beeblink: DEST=~/beeb/beeb-files/stuff
tom_beeblink:
	cp ./BSNova19.ssd $(DEST)/ssds/0/s.nova19

	rm -Rf $(DEST)/BSNova19/0
	ssd_extract --not-emacs -o $(DEST)/BSNova19/0 -0 BSNova19.ssd

.PHONY:tom_dist
tom_dist: BUILD_TIME:=$(shell $(SHELLCMD) strftime -d _ '_Y-_m-_d-_H_M_S')
tom_dist:
	$(SHELLCMD) copy-file BSNova19.ssd $(HOME)/github/tom-seddon.github.io/BSNova19-$(BUILD_TIME).ssd
	cd $(HOME)/github/tom-seddon.github.io && git add BSNova19-$(BUILD_TIME).ssd && git commit -m 'Add BSNova19-$(BUILD_TIME).ssd' && git push
	echo 'https://bbc.godbolt.org/?&disc=https://tom-seddon.github.io/BSNova19-$(BUILD_TIME).ssd&autoboot&model=Master'

##########################################################################
##########################################################################

.PHONY:b2
b2:
	-$(MAKE) _b2

.PHONY:_b2
_b2:
	curl -G 'http://localhost:48075/reset/b2' --data-urlencode "config=Master 128 (MOS 3.20)"
	curl -H 'Content-Type:application/binary' --upload-file 'BSNova19.ssd' 'http://localhost:48075/run/b2?name=BSNova19.ssd'

##########################################################################
##########################################################################

.PHONY:tags
tags:
	/opt/local/bin/ctags --langdef=beebasm --langmap=beebasm:.6502.asm '--regex-beebasm=/^\.(\^|\*)?([A-Za-z0-9_]+)/\2/l,label/' '--regex-beebasm=/^[ \t]*macro[ \t]+([A-Za-z0-9_]+)/\1/m,macro/i' '--regex-beebasm=/^[ \t]*([A-Za-z0-9_]+)[ \t]*=[^=]/\1/v,value/' -eR .
