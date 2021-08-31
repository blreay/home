python
import sys
import os
# https://sourceware.org/gdb/wiki/STLSupport
# move following python folder to $HOME/tools/gdb_stl_python
# svn co svn://gcc.gnu.org/svn/gcc/trunk/libstdc++-v3/python
sys.path.insert(0, os.environ['HOME'] + '/tools/gdb_stl_python')
from libstdcxx.v6.printers import register_libstdcxx_printers
register_libstdcxx_printers (None)

# run "dir" command to add source code search directory
# gdb.execute('directory' + os.environ['SOURCES'] + '/package_name/src')
gdb.execute('directory' + os.environ['PJ'])

# load STL GDB evaluators/views/utilities - 1.03
gdb.execute('source' + os.environ['HOME'] + '/.gdbinit.stl')
end

# load 
#source /home/zhaoyong.zzy/.gdbinit.stl
#source .gdbinit.bk
