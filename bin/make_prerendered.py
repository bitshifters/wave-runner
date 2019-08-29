#!/usr/bin/python
import math,sys,bbc2png,bbc,png,collections,socket,os,random

##########################################################################
##########################################################################

def create_image(w,h,value): return [w*[value] for y in range(h)]

def plot(image,x,y,value):
    if y>=0 and y<len(image) and x>=0 and x<len(image[y]): image[y][x]=value

def plot_points(image,pts,value):
    for x,y in pts:
        y%=len(image)
        x%=len(image[y])
        plot(image,x,y,value)
    
def line(x0,y0,x1,y1):
    pts=[]
    
    dx=x1-x0
    dy=y1-y0

    step=abs(dx if abs(dx)>=abs(dy) else dy)

    dx/=step
    dy/=step

    x=x0
    y=y0
    i=0
    while i<step:
        pts.append((int(x),int(y)))
        x+=dx
        y+=dy
        i+=1

    return pts

def star(cx,cy,rx,ry,theta0):
    line_pts=[]
    num_arms=5
    num_pts=num_arms*2
    x0=None
    y0=None
    for i in range(num_pts+1):
        theta=theta0+float(i)/num_pts*2*math.pi
        r=1.0 if i%2==0 else 0.5
        x=cx+math.sin(theta)*r*rx
        y=cy+math.cos(theta)*r*ry
        if x0 is not None: line_pts+=line(x0,y0,x,y)
        x0=x
        y0=y
    return line_pts

##########################################################################
##########################################################################

def save_file(path,data):
    with open(path,'wb') as f: f.write(''.join([chr(x) for x in data]))

##########################################################################
##########################################################################

def create_pts_image(w,h,bg,fg,pts):
    image=create_image(w,h,bg)
    for x,y in pts:
        y%=len(image)
        x%=len(image[y])
        image[y][x]=fg
    return image

def replicate(image,min_width):
    result=create_image(0,len(image),0)
    while len(result[0])<min_width or len(result[0])%4!=0:
        for y in range(len(image)): result[y]+=image[y]
    return result

##########################################################################
##########################################################################

Part=collections.namedtuple('Part','name image')
Anim=collections.namedtuple('Anim','name offsets')

##########################################################################
##########################################################################

def create_star_parts():
    star_pts=[]
    star_image=create_image(320,16,0)
    for x in range(10):
        for colour in range(1,7):
            r=8-(colour-1)
            plot_points(star_image,
                        star(int((x+0.5)*16),
                             int(8-(x/10.0*8)),
                             r,
                             r,
                             x/10.0*(2*math.pi/5.0)),
                        colour)
    # replicate the left half...
    for y in range(16):
        for x in range(160): star_image[y][160+x]=star_image[(y+8)%16][x]
    
    # star_bbc=bbc.pack_image(star_image,4)
    return [Part('star',star_image)]

##########################################################################
##########################################################################

def create_logo_parts():
    logo_image=bbc.load_png('graphics/bslogo_temp.png',2)
    logo_width=256
    for y in range(len(logo_image)):
        assert len(logo_image[y])%2==0
        extra=(logo_width-len(logo_image[y]))//2
        logo_image[y]=extra*[0]+logo_image[y]+extra*[0]
    print 'logo now %d x %d'%(len(logo_image[0]),len(logo_image))
    # logo_bbc=bbc.pack_image(logo_image,4)
    return [Part('logo',logo_image)]

##########################################################################
##########################################################################

def create_tile_parts():
    single_tile_image=bbc.load_png('graphics/tile_15x16.png',2)
    tiles_image=replicate(single_tile_image,188)
    # tiles_bbc=bbc.pack_image(tiles_image,4)
    return [Part('tiles',tiles_image)]

##########################################################################
##########################################################################

def create_dots_parts():
    single_bg_tile_image=bbc.load_png('graphics/bg_tile_7x8.png',2)
    bg_tiles_image=replicate(single_bg_tile_image,174)
    bg_tiles_bbc=bbc.pack_image(bg_tiles_image,4)
    print 'bg tiles image: %d x %d'%(len(bg_tiles_image[0]),
                                     len(bg_tiles_image))

    parts=[]
    for offset in range(8):
        image=create_image(len(bg_tiles_image[0]),len(bg_tiles_image),0)
        for y in range(len(bg_tiles_image)):
            for x in range(len(bg_tiles_image[0])):
                image[y][x]=bg_tiles_image[(y+offset)%len(image)][x]
        parts.append(Part('dots_y%d'%offset,image))

    return parts

##########################################################################
##########################################################################

def create_7xn_scroll_anims():
    anims=[]
    for left in [True,False]:
        for dx in range(1,6):
            offsets=[]
            print 'dx=%d'%dx
            x=0
            while True:
                offset=x//2
                if x%2!=0: offset+=8
                print '   x=%d offset=%d'%(x,offset)
                offset%=15

                if len(offsets)>0 and offset==offsets[0]: break

                offsets.append(offset)
                x+=dx

            if not left: offsets.reverse()

            dir='left' if left else 'right'
            anims.append(Anim('7xn_%dpx_scroll_%swards'%(dx,dir),
                              offsets))

    return anims

def create_7xn_sine_anims():
    offsets=[]
    num_steps=160
    r=50
    for i in range(num_steps):
        theta=float(i)/num_steps*2.0*math.pi
        x=int(r+math.sin(theta)*r+0.5)
        offset=x//2
        if x%2!=0: offset+=8
        offset%=15
        offsets.append(offset)

    return [Anim('7xn_sine',offsets)]

##########################################################################
##########################################################################

def create_dots_anim(dot_part):
    offsets=[]
    num_steps=50
    r=10
    stride=len(dot_part.image[0])//2 # in CRTC terms
    for i in range(num_steps):
        theta=float(i)/num_steps*2.0*math.pi
        x=int(r+math.sin(theta)*r+0.5)
        y=int(r+math.cos(theta)*r+0.5)
        offset=x//2
        if x%2!=0: offset+=4
        offset%=7
        offset+=(y%8)*stride
        # print 'i=%d theta=%.3f x=%d y=%d offset=$%04x'%(i,theta,x,y,offset)
        offsets.append(offset)
    return [Anim('dots',offsets)]
        
##########################################################################
##########################################################################

LOAD_ADDRESS=0x2000
MAX_ANIMS_SIZE=0x3000-LOAD_ADDRESS

def create_anims_data(anims,data,f):
    for anim in anims:
        while len(data)%2!=0: data.append(0)

        print>>f,'pr_anim_%s=$%04x'%(anim.name,
                                     LOAD_ADDRESS+len(data))
        print>>f,'pr_anim_%s_num_frames=%d'%(anim.name,
                                             len(anim.offsets))

        for offset in anim.offsets: data+=[(offset>>0)&0xff,(offset>>8)&0xff]

##########################################################################
##########################################################################

def create_parts_data(parts,data,f):
    for part in parts:
        # must be some number of character rows high and some number
        # of Mode 2 bytes wide
        assert len(part.image)%8==0
        assert len(part.image[0])%2==0

        stride=len(part.image[0])//2*8
        for row in range(len(part.image)//8):
            addr=LOAD_ADDRESS+len(data)+row*stride
                                        
            print>>f,'pr_part_%s_row%d_crtc_addr=$%04x>>3'%(part.name,
                                                            row,
                                                            addr)
        print '$%04x: %s: %d x %d'%(LOAD_ADDRESS+len(data),
                                    part.name,
                                    len(part.image[0]),
                                    len(part.image))
        data+=bbc.pack_image(part.image,4)
        if LOAD_ADDRESS+len(data)>0x8000: fatal('data too large')

def main():
    parts=[]
    parts+=create_star_parts()
    parts+=create_logo_parts()
    parts+=create_tile_parts()
    first_dot_part_index=len(parts)
    parts+=create_dots_parts()
    for part in parts: assert isinstance(part,Part)

    anims=[]
    anims+=create_7xn_scroll_anims()
    anims+=create_dots_anim(parts[first_dot_part_index])
    anims+=create_7xn_sine_anims()
    for anim in anims: assert isinstance(anim,Anim)

    data=[]
    with open('intermediate/prerendered_tables.6502','wt') as f:
        create_anims_data(anims,data,f)

        if len(data)>MAX_ANIMS_SIZE:
            fatal('anims data too large: size is %d bytes, max is %d bytes'%len(data),MAX_ANIMS_SIZE)

        print '%d anim bytes free'%(MAX_ANIMS_SIZE-len(data))

        while len(data)<MAX_ANIMS_SIZE: data.append(0)
        
        create_parts_data(parts,data,f)

    save_file('intermediate/prerendered.dat',data)

    # with open('intermediate/prerendered_tables.6502','wb') as f:
    #     offset=0
    #     for part in parts:
    #         print '%s: %d x %d, data +$%04x'%(part.name,
    #                                           len(part.image[0]),
    #                                           len(part.image),
    #                                           offset)
    #         assert len(part.image)%8==0
    #         num_rows=len(part.image)//8
    #         assert len(part.image[0])%2==0
    #         stride=len(part.image[0])//2*8
    #         for row in range(num_rows):
    #             row_offset=offset+row*stride
    #             print>>f,'pr_%s_row%d_addr=$%04x'%(part.name,
    #                                                row,
    #                                                0x3000+row_offset)
    #             print>>f,'pr_%s_row%d_offset=$%04x'%(part.name,
    #                                                  row,
    #                                                  row_offset)
                
    #         offset+=num_rows*stride

    #     print>>f,'.bg_tiles_anim_data'
    #     num_steps=50
    #     last_x=None
    #     last_y=None
    #     for i in range(num_steps):
    #         r=10
    #         theta=i/float(num_steps)*2*math.pi
    #         x=int(r+math.sin(theta)*r+0.5)
    #         y=int(r+math.cos(theta)*r+0.5)
    #         print '%d/%d: x=%d y=%d same=%s'%(i,
    #                                           num_steps,
    #                                           x,
    #                                           y,
    #                                           last_x==x and last_y==y)
    #         last_x=x
    #         last_y=y
    #         if x%2==0: x//=2
    #         else: x=4+x//2
    #         print>>f,'equw (pr_bg_tiles_offset%d_row0_offset-pr_bg_tiles_offset0_row0_offset+%d*8)>>3'%(
    #             y%8,
    #             x%7)
    #     print>>f,'equw -1'
            
    # #
    # # Entire screen.
    # # 
    # prerendered_bbc=[]
    # for part in parts: prerendered_bbc+=bbc.pack_image(part.image,4)
    # save_file('intermediate/prerendered.dat',prerendered_bbc)
    
##########################################################################
##########################################################################

if __name__=='__main__': main()
