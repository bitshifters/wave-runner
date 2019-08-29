#!/usr/bin/python
import bbc2png,bbc,png,sys,os,os.path

##########################################################################
##########################################################################

def fatal(msg):
    sys.stderr.write('FATAL: %s\n'%msg)
    sys.exit(1)

##########################################################################
##########################################################################

def create_image(w,h,value): return [w*[value] for y in range(h)]

##########################################################################
##########################################################################

def save_file(path,data):
    with open(path,'wb') as f: f.write(''.join([chr(x) for x in data]))

##########################################################################
##########################################################################

def main():
    stem='anuvverbubbla_8x8'
    
    font_width,font_height,font_pixels,font_metadata=png.Reader(filename='fonts/%s.png'%stem).read()
    font_width=min(font_width,472)
    if font_width%8!=0: fatal('width is %d - not a multiple of 8'%font_width)

    if 'palette' not in font_metadata: fatal('font not palettized')
    font_palette=font_metadata['palette']

    outline_image=create_image(8,font_width,15)
    fg_image=create_image(8,font_width,0)

    for src_y in range(8):
        for src_x in range(font_width):
            colour=font_palette[font_pixels[src_y][src_x]]

            if colour[3]==0:
                # transparent
                outline=0
                fg=0
            elif colour[0]==0 and colour[1]==0 and colour[2]==0:
                # outline
                outline=15
                fg=0
            else:
                # foreground
                outline=0
                fg=15

            dest_x=src_x%8
            dest_y=src_x//8*8+src_y

            outline_image[dest_y][dest_x]=outline
            fg_image[dest_y][dest_x]=fg

    outline_bbc=bbc.pack_image(outline_image,4)
    fg_bbc=bbc.pack_image(fg_image,4)

    all_bbc=[]
    assert len(outline_bbc)==len(fg_bbc)
    for i in range(len(outline_bbc)):
        all_bbc.append(outline_bbc[i])
        all_bbc.append(fg_bbc[i])
        
    dat_path='intermediate/%s.dat'%stem
    save_file(dat_path,all_bbc)
    bbc2png.main(['-o','intermediate/%s.png'%stem,
                  '-c','4',
                  dat_path,'2'])

    # def do_message(str,stem):
    #     stem='message_%s'%stem
    #     assert len(str)<=19

    #     image=create_image(79*2,32,4)

    #     outline_colour=0
    #     text_colour=7

    #     for i in range(len(str)):
    #         c=ord(str[i])
    #         assert c>=32 and c<=ord('Z')
    #         for y in range(24):
    #             for x in range(8):
    #                 dest_x=i*8+x
    #                 dest_y=4+y
    #                 src_x=x
    #                 src_y=(c-32)*8+dest_y//3
    #                 if mask_image[src_y][src_x]!=0:
    #                     if data_image[src_y][src_x]==0: colour=outline_colour
    #                     else: colour=text_colour
                        
    #                     image[dest_y][dest_x]=colour

    #     dat_path='intermediate/%s.dat'%stem
    #     save_file(dat_path,bbc.pack_image(image,4))
    #     bbc2png.main(['-o','intermediate/%s.png'%stem,
    #                   '-c','79',
    #                   dat_path,'2'])
                        
    # #           0123456789012345678
    # do_message('MESSAGE 1','m0')
    # do_message('SOME OTHER MESSAGE','m1')
    # do_message('ABCDEFGHIJKLMNOPQRS','m2')

##########################################################################
##########################################################################

if __name__=='__main__': main()
