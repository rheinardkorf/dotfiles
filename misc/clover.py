#!/usr/bin/python

import sys, getopt
import xml.etree.ElementTree as ET

def process(clover,fname):
    tree = ET.parse(str(clover))
    root = tree.getroot()
    for f in root.iter('file'):
        print f.attrib.get('name')
    #print root
    print fname

def main(argv):
   cloverfile = ''
   try:
      opts, args = getopt.getopt(argv,"hf:",["clover-file="])
   except getopt.GetoptError:
      print 'clover.py <clover.xml> <file.php>'
      sys.exit(2)
   if args[0] != '' and  args[1] != '':
       process(args[0],args[1])
   else:
       print 'Please supply <clover.xml> and <file.php>'
       sys.exit()

   # for opt, arg in opts:
   #    if opt == '-h':
   #       print 'clover.py -f <clover.xml>'
   #       sys.exit()
   #    elif opt in ("-f", "--clover-file"):
   #       cloverfile = arg
   #       process(cloverfile)
   #       sys.exit()

if __name__ == "__main__":
    main(sys.argv[1:])
