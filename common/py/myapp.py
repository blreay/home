#!/usr/bin/env python3
# -*- coding: utf-8 -*-

## HOW to use this light framework
#########################################################
'''
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
import codecs

##################
import myapp

g_appinfo = {"prog": "mytest.py", "description": "Process management tools"}
g_logger = myapp.getlogger()
g_switch = {
    'show_parent': {'func': "ps_find_parent", 'help': '<PID> : show all parent process'},
    'show_child':  {'func': "ps_find_child",  'help': '<PID> : show all child process'},
    'show_all':    {'func': "ps_find_all",    'help': '<PID> : show all parent and child process'},
    'kill_all':    {'func': "ps_kill_all",    'help': '<PID> : kill all child and grandchild process'}
}

# add individual argument for each sub-command
def ps_find_parent_parser(parser_obj, name):
    parser_obj.add_argument('pid', type=int, default='')
    parser_obj.add_argument('-m', type=int, default=1, required=False)
def ps_find_child_parser(parser_obj, name):
    parser_obj.add_argument('pid', type=int, default='')
def ps_find_all_parser(parser_obj, name):
    parser_obj.add_argument('pid', type=int, default=''
def ps_kill_all_parser(parser_obj, name):
    parser_obj.add_argument('pid', type=int, default='')

def main(parser):
    subparsers = parser.add_subparsers(help='supported', title='subcommand',
                                       required=True,
                                       dest='subcommand',
                                       description='all supported command')
    for key in g_switch.keys():
        parser_func_name = f"{g_switch.get(key, default).get('func', 'None')}_parser"
        new_parser_obj = subparsers.add_parser(key, help=f"{g_switch.get(key, default).get('help', 'NONE')}")
        eval(parser_func_name)(new_parser_obj, key)
        new_parser_obj.set_defaults(func=g_switch.get(key, default).get('func', 'None'))

    arg = parser.parse_args()
    eval(arg.func)(arg)

if __name__ == "__main__":
    myapp.run(main, g_appinfo)

'''
######################################################
import os
import signal
import json
import psutil
import time
import subprocess
import threading
import sys
import logging
import argparse
import codecs
import fcntl
# import gflags
# from absl import flags, app

my_logger = logging.getLogger(__name__)

## simple filter to insert thread_id(new attribute)
def thread_id_filter(record):
    """Inject thread_id to log records"""
    record.thread_id = threading.get_native_id()
    return record


def enable_console_stdout_log(arg):
    handler = logging.StreamHandler()
    handler.setFormatter(logging.Formatter('%(asctime)s [%(process)d/%(thread_id)d] %(levelname)5s [%(module)s/%(funcName)s] %(message)s'))
    handler.addFilter(thread_id_filter)
    my_logger.propagate = False
    my_logger.addHandler(handler)
    # my_logger.setLevel(arg.myloglevel)
    my_logger.setLevel("INFO")


def getlogger():
    return my_logger


class DbgAction(argparse.Action):
    def __init__(self, option_strings, dest, nargs=None, **kwargs):
        # if nargs is not None:
        #     raise ValueError("nargs not allowed")
        super().__init__(option_strings, dest, 0, **kwargs)

    def __call__(self, parser, namespace, values, option_string=None):
        print('%r %r 99=%r %s' % (namespace, values, option_string, self.dest))
        # setattr(namespace, self.dest, values)
        setattr(namespace, self.dest, "DEBUG")
        my_logger.setLevel("DEBUG")


def exe_cmd(cmd:str, use_shell=1, stdin=sys.stdin, stdout=sys.stdout, stderr=sys.stderr):
    my_logger.debug(f'run command with popen[{cmd}] stdin={stdin} stdout={stdout} stderr={stderr}')
    obj = subprocess.Popen([cmd], shell=use_shell, stdin=stdin, stdout=stdout, stderr=stderr)
    my_logger.debug(f'popen() return obj[{obj}]')
    # obj.wait()
    # ret = obj.returncode
    return obj

def exe_cmd_sync(cmd:str, use_shell=1, stdin=sys.stdin, stdout=sys.stdout, stderr=sys.stderr):
    my_logger.debug(f'run command with popen[{cmd}] stdin={stdin} stdout={stdout} stderr={stderr}')
    obj = exe_cmd(cmd, use_shell, stdin, stdout, stderr)
    obj.wait()
    ret = obj.returncode
    my_logger.debug(f'command [{cmd}] end with code[{ret}]')
    return ret

def run(func, appinfo):
    sys.stdout = codecs.getwriter("utf-8")(sys.stdout.detach())

    # global g_appinfo
    enable_console_stdout_log(None);

    # create the top-level parser
    parser = argparse.ArgumentParser(description=f'{appinfo["description"]}',
                                     prog=f'{appinfo["prog"]}', formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('-D', '--debug', action=DbgAction, dest='myloglevel',
                        nargs=0, default="INFO", required=False,
                        help='enable debug log')

    ### run user main function
    func(parser)


def load_json_data(file:str):
    my_logger.debug(f'load json data from file [{file}]')
    try:
        with open(file, 'rb') as f:
            params = json.load(f)
    except Exception as e:
        my_logger.exception(f'load json file[{file}] failed with exception[{e}]', exc_info=e)
        raise e
    return params

def write_json_data(params, file:str):
    my_logger.debug(f'write json data to file [{file}]')
    try:
        with open(file, 'w') as r:
            json.dump(params, r)
    except:
        my_logger.exception(f'write json file[{file}] failed with exception[{e}]', exc_info=e)
        # raise e
        return 1
    return 0


def format_json_data(params):
    return json.dumps(params, ensure_ascii=False, indent=4, separators=(',', ':'))

class MyObject:
    def __init__(self):
        self.logger = my_logger
        pass

##############################################################################
## Thread/Process safe named pipe implementation
## used to do communication between 2 process or multithread
## it's using file lock to protect cross-process
##############################################################################
class MySafeNamedPipe(MyObject):
    def __init__(self, pipe_name, logger=None):
        super().__init__()
        self.logger = self.logger if logger is None else logger
        tmp_file_root = "/tmp"
        try:
            self.fifo_path = "{}/{}.pipe".format(tmp_file_root, pipe_name)
            self.logger.info(f'named pipe: fifo path={self.fifo_path}')
            if not os.path.exists(self.fifo_path):
                os.mkfifo(self.fifo_path)
        except Exception as e:
            self.logger.exception(f"exception occured when creating named pipe({pipe_name}) [{e}]", exc_info = e)

        self.block_file = "{}/{}.pipe.lock".format(tmp_file_root, pipe_name)
        self.logger.info(f'block file path={self.block_file}')
        if not os.path.exists(self.block_file):
            f = open(self.block_file, "w")
            f.close()
        self.fp_block = open(self.block_file, "w")

    def __del__(self):
        try:
            self.logger.info(f'remove pipe file: {self.fifo_path}')
            os.remove(self.fifo_path)
        except:
            self.logger.exception(f"exception occured when delete named pipe({self.fifo_path}) [{e}]", exc_info = e)

        try:
            self.logger.info(f'remove lock file: {self.block_file}')
            os.remove(self.block_file)
        except:
            self.logger.exception(f"exception occured when delete named pipe({self.block_file}) [{e}]", exc_info = e)

    def __lock(self, flag=fcntl.LOCK_EX | fcntl.LOCK_NB):
        fcntl.flock(self.fp_block.fileno(), flag)

    def __unlock(self):
        fcntl.flock(self.fp_block.fileno(), fcntl.LOCK_UN)

    def send(self, msg):
        try:
            self.__lock()
            f = os.open(self.fifo_path, os.O_RDWR | os.O_NONBLOCK)
            os.write(f, "{};".format(json.dumps(msg)).encode("utf-8"))
        except Exception:
            self.logger.info(traceback.format_exc())
            return False
        finally:
            self.__unlock()
        return True

    def receive(self):
        msg_str = ""
        try:
            self.__lock()
            f = os.open(self.fifo_path, os.O_RDWR | os.O_NONBLOCK)
            while True:
                try:
                    s = os.read(f, 1).decode("utf-8")
                    #logger.info(f'msg0302 read {s}')
                    if s != ";":
                        msg_str += s
                    else:
                        break
                except BlockingIOError as e:
                    self.__unlock()
                    time.sleep(1)
                    self.__lock()
                    continue
                except Exception:
                    self.logger.info(traceback.format_exc())
                    break
        except Exception as e:
            self.logger.exception(f"exception occured e=[{e}]", exc_info=e)
            return ""
        finally:
            self.__unlock()
        return msg_str
