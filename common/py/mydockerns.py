# coding=utf-8

import commands
import json

class executeException(BaseException):
    pass

def execute(cmd):
    status, output = commands.getstatusoutput(cmd)
    if status != 0:
        raise executeException
    return output

if __name__ == '__main__':
    name = "zzy02"
    ids = execute("docker ps -q | awk '{print $1}'").split('\n')

    for id in ids:
        namespaces = ["ipc", "mnt", "net", "pid", "user", "uts"]
        #short_id = execute("docker ps | grep %s | awk '{print $1}'" % name)
        #short_id = execute("docker ps | grep %s | awk '{print $1}'" % name)
        short_id = id
        print short_id
        full_id = execute("docker inspect -f '{{.Id}}' %s" % short_id)
        print full_id
        state = execute("sudo cat /run/runc/%s/state.json" % full_id)
        f = json.loads(state)
        start_pid = f['init_process_pid']
        print "[INFO] the init_process_pid is %s for container %s" % (start_pid, name)
        ns_index = execute("sudo ls -l /proc/%s/ns | awk '{print $11}'" % start_pid).split('\n')

        # save this ans into dict
        res = {}
        for index in ns_index:
            spr = index.find(":")
            name = index[:spr]
            num = index[spr+2: -1]
            #print name, num
            res[name] = num

        # print
        for ns in namespaces:
            print ns, res[ns]
