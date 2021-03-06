#!/usr/bin/python
#coding=UTF-8
# 在Linux下面浏览代码，一般都是Vim／Emacs加上tags和cscope的组合。但是，ctags和cscope程序在生成相应的索引文件时，一般都是默认查找项目中的所有文件，这样就会在项目较大时造成索引文件过大的后果，比如Linux kernel，解压缩之后有几百M，如果完全索引，对应的ctags文件和cscope文件加起来也有一百多M，这样间接的也造成了如果有新的文件加入项目中想重新生成索引文件时时间过长。当然可以使用find＋grep命令指定需要查找的文件和目录，把这些文件路径写入一个文件，然后再调用ctags和cscope根据该文件中记录的文件来生成索引，但是毕竟这样做麻烦。

#mktags项目就是基于要上面需要解决的几个问题而出现的，它的目的是可以让使用者指定需要关注的项目路径和文件类型，然后根据这些来生成索引文件。
# 比如，我可以在存放Linux kernel代码的路径中键入如下命令：
#mktags -a include/ arch/ mm/  kernel/ ipc/ -t .c .h
#表示我只关注 include.arch,mm,kernel,ipc下面的.c和.h文件

#项目地址在:
#http://code.google.com/p/mktags/

__author__ = "Lichuang"
__version__ = "0.4"
__copyright__ = "Copyright (c) 2009 Lichuang"
__license__ = "GPL"

import sys
import getopt
import os
import ConfigParser

class PathInfo:
	def __init__(self, path, depth):
		self.path = path
		self.depth = depth
						  
class DirWalkArgs:
	def __init__(self, fileobj, depth):
		self.fileobj = fileobj
		self.depth = depth
						  
IndexFile = "mktags.files"
ConfigFile = "mktags.conf"
FileTypeList = []						
PathDic = {}
AddPathInfoList = []
DelPathList = []
RootDir = "."
MaxDirDepth = 9999999
DefaultFileType = ".c .h"
GenerateIndexFile = 0
GotoMktags = 0

def usage():
	print "mktags written by lichuang, version " + __version__
	print "usage: mktags [option]"
	print "option:"
	print "\t-a\tadd directory, each splited by space,\"--depth=X\" give the walk depth,"
	print "\t\tdefault visit all the files and directories in the path"
	print "\t-n\tappend new path into the existing directories, each splited by space,\"--depth=X\" give the walk depth,"
	print "\t-d\tdelete exist source directory, each splited by space"
	print "\t-t\tadd file type, such as \".c\", each splited by space"				   
	print "\t-i\tthe index file, mktags.files by default"				   
	print "\t-c\tsave the search path and file types in the configure file, mktags.conf by default"				   
	print "\t-s\tshow search path and file types in the configure file"
	print "\t-r\tclean all the mktags configure , tags, cscope* files"
	print "\t-g\tgenarate the index file only, not execute cscopt and ctags"
	print "example:"
	print "\texecute"
	print "\t\"mktags -a fs/ --depth=1 -a mm/ -t .c .h\""
	print "\tin the Linux Kernel source directory, add the *.c,*.h files in the fs directory,"
	print "\tnot including the sub-directories, and all the *.c,*.h files in the mm directory"
	print "\tinto the tags and cscope database"

def show_conf():
	config = ConfigParser.RawConfigParser()

	config.read(ConfigFile)
	print "file types are:"
	print config.get("global", "filetype") + "\n"

	print "paths and depths are:"
	for section in config.sections():
		if section != "global":
			print "path:\t",  config.get(section, "path")
			print "depth:\t", config.get(section, "depth") + "\n"

def clean_project():
	cmd = "rm cscope* -f"
	os.system(cmd)
	cmd = "rm tags -f"
	os.system(cmd)
	cmd = "rm mktags* -f"
	os.system(cmd)

def write_to_file(file, path):
	if len(FileTypeList) != 0:
		if not os.path.splitext(path)[1] in FileTypeList:
			return
	file.write(path + "\n")

def visit(arg, dir, filelist):
	if arg.depth == 0:
		return

	arg.depth -= 1

	for name in filelist:
		# ignore the hiding file and directory
		if name[0] == ".":
			continue
		path = os.path.join(dir, name)
		if not os.path.isdir(path) and os.path.isfile(path):  
			write_to_file(arg.fileobj, path)

def visit_dir(arg, dir, filelist):
	visit(arg, dir, filelist)

def search_files():
	print "\nNow searching directory to generate index file......"	

	fileobj = open(IndexFile, "w")
	if len(AddPathInfoList) != 0 :
		for pathinfo in AddPathInfoList:								  
			os.path.walk(pathinfo.path, visit_dir, DirWalkArgs(fileobj, pathinfo.depth))
	else :
		# default add all the files into the search file
		os.path.walk(RootDir, visit_dir, DirWalkArgs(fileobj, MaxDirDepth))
	
	fileobj.close()

	print "Search directory to generate index file done!"	

def make_cscope():
	cmd = "rm cscope* -f"
	os.system(cmd)
	print "\nNow generating cscope database......"
	cmd = "cscope -bkq -i " + IndexFile
	print "execute: " + cmd
	os.system(cmd)
	print "Generate cscope database done!"
						
def make_tags():
	cmd = "rm tags -f"
	os.system(cmd)
	print "\nNow generating tags file......"	
	#cmd = "ctags -L " + IndexFile
	cmd = "ctags --c++-kinds=+p --fields=+iaS --extra=+q -L " + IndexFile
	print "execute: " + cmd
	os.system(cmd)
	print "Generate tags file done!"	

def join_path():
	global AddPathInfoList
	index = len(AddPathInfoList)

	if index == 0:
		read_conf()
	else:
		config = ConfigParser.ConfigParser()

		global ConfigFile

		tmplist = []
		for pathinfo in AddPathInfoList:
			path = os.path.join(RootDir, pathinfo.path)
			if (DelPathList.count(path) == 0):
				if not os.access(path, os.X_OK):
					print "error: cannot access " + path + "!"
					sys.exit(-2)
				tmplist.append(PathInfo(path, pathinfo.depth))
				section = "path" + str(index)
				config.add_section(section)
				config.set(section, 'path', pathinfo.path)
				config.set(section, 'depth', pathinfo.depth)
				index = index - 1
		config.add_section('global')

		if len(FileTypeList) != 0 :
			filetype = " ".join(FileTypeList)
		else :
			filetype = DefaultFileType

		config.set('global', 'filetype', filetype)
			
		AddPathInfoList = tmplist

		config.write(open(ConfigFile, "w"))

def welcome():	
	print "Welcome to using mktags version " + __version__

	if (len(FileTypeList) < 2):
		print "\nThe file type you want to add to tags is: "
	else:		
		print "\nThe file types you want to add to tags are: "
	for type in FileTypeList:
		print type 

	if (len(AddPathInfoList) < 2):
		print "\nThe directory you want to search is: "
	else:		
		print "\nThe directories you want to search are: "
	for pathinfo in AddPathInfoList:
		print pathinfo.path

def add_arg_to_list(i, len, arglist, addlist):
	while (i < len):
		if arglist[i][0] == '-':
			break										 
 		addlist.append(arglist[i])
		i = i + 1
	return i			 

def parse_add_path_list(i, arg_len, arglist, new_flag):
	add_path_list = []
	depth = MaxDirDepth # give a large enough depth by default
	depth_opt = "--depth="					   
	opt_len = len(depth_opt)											   

	while (i < arg_len):
		if arglist[i][0] == '-':
			if arglist[i][0:opt_len] == depth_opt:
				str = arglist[i][opt_len:]
				if not str.isdigit():
					print "Invalid option ", arglist[i]								 
					usage()
					sys.exit(-2)						   
				depth = int(str)
			else:
				break
		else:								
 			add_path_list.append(arglist[i])
			
		i = i + 1

	for path in add_path_list:
		AddPathInfoList.append(PathInfo(path, depth))

	if new_flag == 0:
		read_conf()

	return i			 

def read_conf():
	global ConfigFile
	global FileTypeList
	global AddPathInfoList
	global DelPathList

	if not os.access(ConfigFile, os.R_OK | os.W_OK):
		print "can not read | write configure file ", ConfigFile
		sys.exit(-2)

	config = ConfigParser.RawConfigParser()

	config.read(ConfigFile)
	FileTypeList = config.get("global", "filetype").split()

	for section in config.sections():
		if section != "global":
			path = config.get(section, "path")
			if DelPathList.count(path) == 0:
				AddPathInfoList.append(PathInfo(path, config.getint(section, "depth")))
			else :
				config.remove_section(section)
	
	# save the new configure
	config.write(open(ConfigFile, "w"))

def parse_args():
	arg_len = len(sys.argv)

	global GotoMktags

	if arg_len == 1:
		GotoMktags = 1
		return

	global IndexFile
	global RootDir
	global AddPathInfoList
	global ConfigFile
	global GenerateIndexFile

	i = 1
	while (i < arg_len):
		opt = sys.argv[i]
		i = i + 1
		if opt == "-t":
			i = add_arg_to_list(i, arg_len, sys.argv, FileTypeList)					   
		elif opt == "-a":
			i = parse_add_path_list(i, arg_len, sys.argv, 1)
		elif opt == "-n":
			i = parse_add_path_list(i, arg_len, sys.argv, 0)
		elif opt == "-d":
			i = add_arg_to_list(i, arg_len, sys.argv, DelPathList)
		elif opt == "-i":
			if (i >= arg_len):
				print "unassign the index file name!"
				usage()
				sys.exit(-2)					   
			IndexFile = sys.argv[i]
			i = i + 1								   
		elif opt == "-h":
			usage()
			sys.exit(0)
		elif opt == "-c":
			ConfigFile = sys.argv[i]						 
			i = i + 1
		elif opt == "-s":
			show_conf()
			sys.exit(0)
		elif opt == "-r":
			clean_project()
			sys.exit(0)
		elif opt == "-g":
			GenerateIndexFile = 1
			i = i + 1
		else:
			print "illegal argument:", opt
			usage()
			sys.exit(-1)

def done():
	print "\nThe cscope and tags file have been generated, enjoy!"

if __name__ == "__main__":    
	parse_args()

	if GotoMktags == 0:
		join_path()
		welcome()
		search_files()
		if GenerateIndexFile == 1:
			sys.exit(0)

	make_cscope()
	make_tags()
	done()


