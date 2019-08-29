#!/usr/bin/python
import math,sys,bbc2png,bbc,png,collections,socket,os,random

##########################################################################
##########################################################################

def create_image(w,h,value): return [w*[value] for y in range(h)]

def save_file(path,data):
    with open(path,'wb') as f: f.write(''.join([chr(x) for x in data]))

##########################################################################
##########################################################################

def print_hi_lo_tables(f,stem,values,expr_suffix=''):
    def print_hi_lo_table(op,shift):
        label='%s_%s'%(stem,op)
        print>>f,'.%s'%label
        for value in values: print>>f,'equb %s($%x%s)'%(op,
                                                        value,
                                                        expr_suffix)
        print>>f,'must_be_same_page %s'%label
        
    print_hi_lo_table('hi',8)
    print_hi_lo_table('lo',0)

# PaletteWrite=collections.namedtuple('PaletteWrite','offset')
    
def print_tables(f):
    for row in range(8):
        frame_addrs=[]
        for frame in range(16):
            frame_addr=0x3000

            frame_addr+=(frame&3)*0xc00

            if frame<8:
                frame_addr+=(row&3)*0x300
                if row>=4: frame_addr+=0x80
            else:
                if row<4: frame_addr+=0x80
                frame_addr+=(~row&3)*0x300
            
            #addrs=[0x3000+(frame&3)*0xc00+row_base for frame in range(8)]
            frame_addrs.append(frame_addr)
            
        print_hi_lo_tables(f,
                           'cheq_frame_crtc%ds'%row,
                           frame_addrs,
                           '>>3')
    
    print>>f,'.cheq_frame_palettes'
    for i in range(16): print>>f,'equb %d'%(0 if (i&4)==0 else 16)
    print>>f,'must_be_same_page cheq_frame_palettes'

    # layer_colours=[0,1,2,3]m
    print>>f,'.cheq_palette'
    offset=0
    for shift in [0,1]:
        for j in range(16):
            layer_colour=j>>(shift*2)&3
            print>>f,'equb $%02x ; index %d = colour %d (+%d)'%(j<<4|layer_colour^7,
                                                                j,
                                                                layer_colour,
                                                                offset)
            offset+=1
            
    print>>f,'must_be_same_page cheq_palette'

    for layer_colour in range(4):
        print>>f,'.cheq_set_colour%d'%layer_colour
        writes={}
        for shift in [0,1]:
            for j in range(16):
                if (j>>(shift*2)&3)==layer_colour:
                    writes.setdefault(j,[]).append(shift*16+j)

        old_index=0
        for index in sorted(writes.keys()):
            line=''
            if index!=old_index:
                line+='eor #$%02x:'%((index^old_index)<<4)
                old_index=index
            line+=':'.join(['sta cheq_palette+%d'%offset
                            for offset in writes[index]])
            print>>f,line
        print>>f,'rts'
        print>>f

        # print>>f,writes
        #             # print>>f,'; set +%d'%(shift*8+j)
        #             if j!=old_index:
        #                 print>>f,'eor #$%02x'%((j^old_index)<<4)
        #                 old_index=j
        #             print>>f,'sta cheq_palette+%d'%(shift*16+j)
        # print>>f,'rts'
        # print>>f,''
    
##########################################################################
##########################################################################

Layer=collections.namedtuple('Layer','width colour scale')

def is_set(value,layer): return value%(layer.width*2)<layer.width

def main():
    layers=[
        Layer(64,1,4),
        Layer(32,2,2),
        Layer(16,3,1),
    ]

    # Create reference images.
    for frame in range(8):
        image=create_image(160,256,0)
        for y in range(len(image)):
            for x in range(len(image[y])):
                for layer_idx,layer in enumerate(layers):
                    # scale x by 2 to correct, roughly, for the Mode 2
                    # aspect ratio
                    xset=is_set(((x+frame*layer.scale)*2),layer)
                    yset=is_set(y,layer)
                    if xset!=yset:
                        image[y][x]=layer.colour
                        break

        stem='intermediate/cheq_frame%d'%frame
        dat_path='%s.dat'%stem

        bbc_dat=bbc.pack_image(image,4)
        save_file(dat_path,bbc_dat)

        if sys.platform=='darwin' and os.getenv('USER')=='tom' and socket.gethostname()=='tmbp.local': save_file(os.path.expanduser('~/beeb/beeb-files/stuff/BSNova19/1/D.FRAME%d'%frame),bbc_dat)

        bbc2png.main(['-o','%s.png'%stem,
                      dat_path,'2'])

    # Create full 2bpp image.

    # must be possible to fit into 2bpp...
    for layer in layers: assert layer.colour<4
    
    image_2bpp=create_image(192,256,0)
    y=0
    for frame in range(8):
        for row in range(4):
            for x in range(192):
                for scanline in range(8):
                    y=frame*32+row*8+scanline
                    for layer in layers:
                        xset=is_set(((x+frame*layer.scale)*2),layer)
                        yset=is_set((row*8+scanline)*2,layer)
                        if xset!=yset:
                            assert y>=0 and y<len(image_2bpp),y
                            assert x>=0 and x<len(image_2bpp[y]),x
                            image_2bpp[y][x]=layer.colour
                            break

    save_file('intermediate/cheq_full.dat',bbc.pack_image(image_2bpp,2))
    bbc2png.main(['-o','intermediate/cheq_full.png',
                  '-c','48',
                  '-p','0147',
                  'intermediate/cheq_full.dat','5'])

    # Create doubled-up half-height 4bpp image.
    assert len(image_2bpp)%2==0
    image_4bpp=create_image(len(image_2bpp[0]),
                            len(image_2bpp)//2,
                            0)
    for y in range(0,len(image_4bpp)):
        for x in range(len(image_4bpp[y])):
            a=image_2bpp[y][x]
            b=image_2bpp[len(image_2bpp)//2+y][x]
            
            image_4bpp[y][x]=a|b<<2

    bbc_image_4bpp=bbc.pack_image(image_4bpp,4)

    # # Stuff some extra bits at the end. Easiest to do offline.
    # for i in range(632*79*8):

    # Stuff some blue at the end. Easiest to generate offline.

    while len(bbc_image_4bpp)<20480:
        bbc_image_4bpp.append(bbc.pack_4bpp([4,4]))
    
    # #
    # # For bbc2png purposes, must conform to the 96-column stride. This
    # # is a bit stupid, but Exomizer will ensure this won't take up too
    # # much extra space.
    # for i in range(5):
    #     for j in range(79*2):
    #         for k in range(8):
    #             colour=4
    #             bbc_image_4bpp.append(bbc.pack_4bpp([colour,colour]))
    # while len(bbc_image_4bpp)%(96*8)!=0: bbc_image_4bpp.append(bbc_image_4bpp[-1])
    
    save_file('intermediate/cheq_full_4bpp.dat',bbc_image_4bpp)

    # 20480%(96*8)!=0, so bbc2png isn't an option...
    
    # bbc2png.main(['-o','intermediate/cheq_full_4bpp.png',
    #               '-c','96',
    #               '--16',
    #               'intermediate/cheq_full_4bpp.dat','2'])

    # 6502 tables.
    with open('intermediate/cheq_tables.6502','wt') as f: print_tables(f)

    # A bit of data that's easier to pre-generate here.

##########################################################################
##########################################################################

if __name__=='__main__': main()
