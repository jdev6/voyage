NAME:=voyage
MAINTAINER:=jdev6
FILES:=*.lua lib/ *.mp3 *.png *.ttf
ICON:=ship.png
EXT:=CREDITS.txt
LOVEVERSION:=0.10.1

run:
	love .

love:
	mkdir lovetmp || :
	cp *.lua lib *.mp3 *.png *.ttf ./lovetmp -r
	cd lovetmp && zip -9 -q -r ../builds/$(NAME).love .
	rm -rf ./lovetmp

win: love
	cat love-$(LOVEVERSION)-win32/love.exe builds/$(NAME).love > builds/$(NAME).exe
	cp love-$(LOVEVERSION)-win32/*.dll $(EXT) builds/
	cd builds && zip -9 -q -r $(NAME)-win.zip $(NAME).exe *.dll $(EXT)
	rm builds/*.dll builds/$(EXT)  builds/$(NAME).exe

mac: love
	cp -r love-$(LOVEVERSION).app builds/$(NAME).app
	cp builds/$(NAME).love builds/$(NAME).app/Contents/Resources/
	PROJECT_ICNS="$(ICON)" MAINTAINER_NAME=$(MAINTAINER) PACKAGE_NAME=$(NAME) PROJECT_NAME=$(NAME) LOVE_VERSION=$(LOVEVERSION)  ./macbuild.sh > "builds/$(NAME).app/Contents/Info.plist"
	cp $(ICON) builds/$(NAME).app/Contents/Resources
clean:
	rm builds/* -rf
