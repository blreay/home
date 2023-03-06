#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import os
import signal
import psutil
import time
import threading
import sys
import logging
import argparse
from treelib import Tree, Node
# from absl import flags, app

# import my light python framework
import myapp

## Global variables
###########################################################
#g_appinfo = {"prog": "ps.py", "description": "Process management tools"}
g_logger = myapp.getlogger()
g_switch = {
    'image':       {'func': "k8s_getimage",  'help': 'show image information'}
}
g_cmd_image_get_all = ''' kubectl get pods --all-namespaces -o jsonpath="{.items[*].spec.containers[*].image}" | \
tr -s '[[:space:]]' '\n' | \
sort | \
uniq -c'''
g_cmd_image_get_by_pod = '''kubectl get pods --all-namespaces \
-o jsonpath='{range .items[*]}{"\n"}{.metadata.name}{":\t"}{range .spec.containers[*]}{.image}{", "}{end}{end}' |\
sort'''
############################################################
def k8s_getimage(args):
    g_logger.debug(f'args=[{args}]')
    cmd = g_cmd_image_get_all
    if args.get_all_image == 1:
        cmd = g_cmd_image_get_all
    elif args.get_image_by_pod == 1:
        cmd = g_cmd_image_get_by_pod

    ret = myapp.exe_cmd_sync(cmd)
    g_logger.debug(f'ret={ret} cmd=[{cmd}]')

def default():
    print('default')

# add individual argument for each sub-command
def k8s_getimage_parser(parser_obj, name):
    parser_obj.add_argument('subcmd', nargs='?', type=str, default='img_cmd', help='default is ""(run all case)')
    parser_obj.add_argument('-a', '--get-all-image',  action='store_const', const=1, default=0, dest='get_all_image',
                        required=False, help='get all pod image')
    parser_obj.add_argument('-p', '--get-image-by-pod',  action='store_const', const=1, default=0, dest='get_image_by_pod',
                        required=False, help='get all image by pod')

def main(parser):
    subparsers = parser.add_subparsers(help='supported', title='subcommand',
                                       dest='subcommand',
                                       description='all supported command')
    for key in g_switch.keys():
        func = g_switch.get(key, default).get('func', 'None')
        parser_func_name = f"{g_switch.get(key, default).get('func', 'None')}_parser"
        new_parser_obj = subparsers.add_parser(key, help=f"{g_switch.get(key, default).get('help', 'NONE')}")
        eval(parser_func_name)(new_parser_obj, key)
        new_parser_obj.set_defaults(func=func)

    arg = parser.parse_args()
    # arg = myapp.parse(parser)
    g_logger.debug(f'commandline parse result: [{arg}]')

    # if no valid command is specified, show help msg
    if not hasattr(arg, 'func'):
        parser.parse_args(['-h', '-a'])

    eval(arg.func)(arg)
    g_logger.debug(f'main end')


if __name__ == "__main__":
    g_logger.debug(f'python entry begin')
    #myapp.run(main, g_appinfo)
    myapp.run(main)
    g_logger.debug(f'python entry end')
