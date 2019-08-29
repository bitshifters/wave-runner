#!/usr/bin/python
import os,os.path,hashlib,argparse,subprocess,sys,pipes

##########################################################################
##########################################################################
# 
# run Exomizer on a file only if that file or the Exomizer args
# changed since last time.
#
# Ideally, Makefile targets that run Exomizer should depend on the
# Makefile as well as the input file, as the Makefile contains
# relevant info - the unpack address. But it's no fun to have
# everything repack even if some unrelated part of the Makefile was
# altered.
#
# This script skips the Exomizer step if the input file contents,
# input path (as a string, including address) and Exomizer args are
# the same as on the last successful compression step. A target that
# runs this script can depend on the Makefile, and it won't take long
# to run if nothing has actually changed.
# 
##########################################################################
##########################################################################

g_verbose=False

def v(str):
    global g_verbose
    
    if g_verbose:
        sys.stdout.write(str)
        sys.stdout.flush()

##########################################################################
##########################################################################

def fatal(str):
    sys.stderr.write('FATAL: %s'%str)
    if str[-1]!='\n': sys.stderr.write('\n')
    
    sys.exit(1)

##########################################################################
##########################################################################

def exo(options):
    global g_verbose
    g_verbose=options.verbose

    if '@' not in options.input: fatal('load address not supplied')

    input_hasher=hashlib.sha1()
    input_path=options.input[:options.input.index('@')]
    with open(input_path,'rb') as f: input_hasher.update(f.read())
    v('%s  %s\n'%(input_hasher.hexdigest(),input_path))

    new_info_text='%s %s %s'%(input_hasher.hexdigest(),' '.join(options.exo_args),options.input)
    old_info_text=None
    
    info_path='%s.info.txt'%os.path.splitext(options.output_path)[0]
    try:
        with open(info_path,'rt') as f: old_info_text=f.read().strip()
    except IOError,e: pass

    v('old info: %s\n'%old_info_text)
    v('new info: %s\n'%new_info_text)

    if old_info_text==new_info_text:
        # update output file's time, as if it were rebuilt.
        os.utime(options.output_path,None) # None=now
    else:
        args=([options.exomizer]+
              options.exo_args+
              ['-o',options.output_path]+
              [options.input])

        v('running exomizer: %s\n'%(' '.join(['``'+pipes.quote(arg)+'\'\'' for arg in args])))
        
        exo_result=subprocess.call(args)
        if exo_result!=0: fatal('Exomizer exit code: %d'%exo_result)

        # only save the info text when successful.
        with open(info_path,'wt') as f: f.write(new_info_text)

##########################################################################
##########################################################################

def main(argv):
    parser=argparse.ArgumentParser()
    parser.add_argument('-v','--verbose',action='store_true',help='be more verbose')
    parser.add_argument('-e','--exomizer',metavar='FILE',default='exomizer',help='use %(metavar)s as Exomizer binary')
    parser.add_argument('input',metavar='INPUT',help='input, FILE@ADDR')
    parser.add_argument('output_path',metavar='OUTPUT',help='output')
    parser.add_argument('exo_args',metavar='EXO-ARG',nargs=argparse.REMAINDER,help='additional Exomizer args (-o and input will be appended automatically)')
    exo(parser.parse_args(argv))

##########################################################################
##########################################################################
    
if __name__=='__main__': main(sys.argv[1:])
