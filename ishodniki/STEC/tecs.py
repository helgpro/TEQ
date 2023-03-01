
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function
from __future__ import unicode_literals

import os
import sys
from builtins import str
from tecs.__main__ import run

if os.name == 'nt':
    try:
        wd = os.getcwd()
        os.environ['PATH'] = "%s;%s" % (wd, os.environ['PATH'])
        run()
    except Exception as err:
        print(str(err))
    finally:
        msg = '\nPress Enter key to close the window.'
        print(msg)
        sys.stdin.readline()
else:
    run()
