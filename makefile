NAME:=voyage
FILES:=*.lua lib/ *.mp3 *.png *.ttf
EXT:=CREDITS.txt

run:
	love .

love:
	mkdir lovetmp || :
	cp *.lua lib *.mp3 *.png *.ttf ./lovetmp -r
	cd lovetmp && zip -9 -q -r ../builds/$(NAME).love .
	rm -rf ./lovetmp

win: love
	cat love-0.10.1-win32/love.exe builds/$(NAME).love > builds/$(NAME).exe
	cp love-0.10.1-win32/*.dll $(EXT) builds/
	cd builds && zip -9 -q -r $(NAME)-win.zip $(NAME).exe *.dll $(EXT)
	rm builds/*.dll builds/$(EXT)  builds/$(NAME).exe

mac: love #todo

clean:
	rm builds/* -i
