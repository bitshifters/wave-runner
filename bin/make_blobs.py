#!/usr/bin/python
import math,sys,bbc2png,bbc,collections,png

##########################################################################
##########################################################################

BASE=0x2000

##########################################################################
##########################################################################

def create_image(w,h,value): return [w*[value] for y in range(h)]
    
def fill_ellipse(image,cx,cy,rx,ry,value):
    rx2_recip=rx*rx
    rx2_recip=float('inf') if rx2_recip==0 else 1.0/rx2_recip

    ry2_recip=ry*ry
    ry2_recip=float('inf') if ry2_recip==0 else 1.0/ry2_recip
    
    for y,row in enumerate(image):
        for x in range(len(row)):
            dx=(x+.5)-cx
            dy=(y+.5)-cy

            if (dx*dx)*rx2_recip+(dy*dy)*ry2_recip<=1.0:
                row[x]=value

def save_file(path,data):
    with open(path,'wb') as f: f.write(''.join([chr(x) for x in data]))
        # f.write(''.join([chr(x) for x in bbc.pack_image(image,
        #                                                 bpp)]))
            
##########################################################################
##########################################################################

def lerp(a,b,t):
    assert t>=0 and t<=1
    return a+(b-a)*t

PNG=collections.namedtuple('PNG','w h data metadata')

def read_png(filename):
    w,h,data,metadata=png.Reader(filename=filename).asRGBA8()
    return PNG(w,h,list(data),metadata)

def getpixel(png,x,y):
    assert y>=0 and y<png.h
    assert x>=0 and x<png.w

    return png.data[y][x*4+0:x*4+4]

Glyph=collections.namedtuple('Glyph','image')
Command=collections.namedtuple('Command','name num_frames')

g_commands=[
    Command('regular',0),
    Command('italics',0),
    Command('off',7),
    Command('on',7),
    Command('off_instant',0),
    Command('on_instant',0),
    Command('set_pic',0),
    Command('do_scroll_text',0),
    Command('restart',0),
    Command('scroll_9x',9*9),
    Command('wait',0),
    Command('cls',0),
    Command('transition_on',32),
    Command('transition_off',32),
    Command('blobs_mode',0),
]

class Builder:
    def __init__(self):
        self._data=[]
        self._num_frames=0
        self._italics=False

    @property
    def num_frames(self): return self._num_frames

    def get_data(self):
        assert len(self._data)<0x1000
        data=self._data[:]
        while len(data)<0x1000: data.append(0)
        return data

    def cmd(self,name):
        for index,command in enumerate(g_commands):
            if command.name==name:
                self._data.append(index*2)

                if name=='italics': self._italics=True
                elif name=='regular': self._italics=False

                self._num_frames+=command.num_frames

                return

        assert False,name

    def wait(self,num_frames):
        assert num_frames>=1 and num_frames<=256
        self.cmd('wait')
        self._data.append(num_frames&0xff)
        self._num_frames+=num_frames

    def set_pic(self,offset,pic):
        assert offset>=0 and offset<=8
        assert len(pic)==8
        for y in range(len(pic)): assert len(pic[y])==9
        self.cmd('set_pic')
        self._data.append(offset)
        for x in range(9):
            for y in range(8):
                self._data.append(pic[y][x])

    def scroll_9x(self,flags):
        assert flags>=0 and flags<256
        self.cmd('scroll_9x')
        self._data.append(flags)
        self._num_frames+=9*9

    def scroll_text(self,text,glyphs):
        image=create_image(0,8,0)
        for c in text:
            assert c in glyphs,c
            if len(image[0])>0:
                for row in image: row.append(0)

            glyph_image=glyphs[c].image
            for y in range(len(image)): image[y].extend(glyph_image[y])

        while len(image[0])%8!=0:
            for row in image: row.append(0)

        assert len(image[0])//8<=256

        bbc_image=bbc.pack_image(image,1)

        end_addr=BASE+len(self._data)+4+len(bbc_image)

        self.cmd('do_scroll_text')
        self._data.append((len(image[0])//8)&0xff)                # +2
        self._data.append((end_addr>>0)&0xff)                     # +3
        self._data.append((end_addr>>8)&0xff)                     # +4
        self._data.extend(bbc_image)
        assert BASE+len(self._data)==end_addr

        self._num_frames+=len(image[0])*8
        if self._italics: self._num_frames+=7

def main():
    print 'create images...'
    num_rows=7
    blobs_image=create_image(180,num_rows*32,15)
    for row in range(num_rows):
        for col in range(10):
            x=9+col*18
            y=16.5+row*32
            xr=9
            yr=16
            rt=row/(num_rows-1.0)
            # rt=abs(math.cos(rt*math.pi))
            rscale=math.sin(rt*0.5*math.pi)
            # rscale=0.5+(1-rt)*0.5
            fill_ellipse(blobs_image,x,y,xr,yr*rscale,col)
    blobs_bbc=bbc.pack_image(blobs_image,4)
    save_file('intermediate/blobs_image.dat',blobs_bbc)
    print 'create BBC image...'
    bbc2png.main(['-c','90',
                  '-o','intermediate/blobs_image.png',
                  'intermediate/blobs_image.dat','2'])
    
    print 'load font PNG...'
    font=read_png('fonts/simple_6x8.png')
    
    glyphs={}
    print 'font_pic: %d x %d, %d'%(font.w,font.h,len(font.data[0]))
    assert font.h==8
    glyph_width=6
    assert font.w%glyph_width==0
    for index in range(font.w//glyph_width):
        ascii=32+index
        glyph_image=create_image(glyph_width,8,0)
        for y in range(font.h):
            for x in range(glyph_width):
                pixel=getpixel(font,index*glyph_width+x,y)
                assert len(pixel)==4
                if pixel[3]>=128: glyph_image[y][x]=1

        min_x=glyph_width+1
        max_x=-1
        for y in range(len(glyph_image)):
            for x in range(len(glyph_image[y])):
                if glyph_image[y][x]!=0:
                    min_x=min(min_x,x)
                    max_x=max(max_x,x+1)

        if max_x<0:
            # entirely empty - resize to 4xn
            glyph_image=create_image(4,len(glyph_image),0)
        else:
            # truncate
            for y in range(len(glyph_image)):
                glyph_image[y]=glyph_image[y][min_x:max_x]

        assert chr(ascii) not in glyphs
        glyphs[chr(ascii)]=Glyph(glyph_image)

    icons=bbc.load_png('graphics/9x8_icons.png',2)
    flux=icons[0:8]
    acorn=icons[8:16]

    b=Builder()
    b.cmd('transition_on')
    b.cmd('blobs_mode')
    b.cmd('on_instant')
    b.cmd('italics')
    b.scroll_text('Bitshifters',glyphs)
    b.scroll_9x(0)
    b.cmd('off_instant')
    b.cmd('regular')
    b.set_pic(4,flux)
    b.cmd('on')
    b.wait(150)
    b.cmd('off')
    b.set_pic(4,acorn)
    b.cmd('on')
    b.wait(150)
    b.scroll_9x(0xaa)
    b.cmd('transition_off')
    blobs_anim_num_frames=b.num_frames
    # add in some dead time, as I don't trust the results to be fully
    # accurate
    b.wait(255)
    # always restart anyway as it's useful for testing.
    b.cmd('restart')

    # text_image=create_image(0,8,0)
    # for c in text:
    #     assert c in glyphs,c
    #     if len(text_image[0])>0:
    #         for row in text_image: row.append(0)

    #     glyph_image=glyphs[c].image
    #     for y in range(len(text_image)):
    #         text_image[y].extend(glyph_image[y])

    # while len(text_image[0])%8!=0:
    #     for row in text_image: row.append(0)

    # print glyphs[' ']

    # text_bbc=bbc.pack_image(text_image,1)

    save_file('intermediate/blobs.dat',b.get_data()+blobs_bbc)

    # ensure the indexes match up.
    with open('intermediate/blobs_tables.6502','wt') as f:
        print>>f,'blobs_anim_num_frames=%d'%blobs_anim_num_frames
        print>>f,'.blobs_command_routines'
        for index,command in enumerate(g_commands):
            print>>f,'equw blobs_%s ; %d'%(command.name,index*2)

if __name__=='__main__': main()
