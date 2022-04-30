import sys
import os


def do_ren_openerp(ffn):
    found_token = False
    with open(ffn, 'r') as fd:
        lines = fd.read().split('\n')
        for nro, line in enumerate(lines):
            if line and line.startswith("from openerp"):
                lines[nro] = line.replace("openerp", "odoo")
                found_token = True
    if found_token:
        bakfile = '%s~' % ffn
        if os.path.isfile(bakfile):
            os.remove(bakfile)
        if os.path.isfile(ffn):
            os.rename(ffn, bakfile)
        with open(ffn, 'w') as fd:
            fd.write("\n".join(lines))
            print(ffn)


def main(argv):
    argv = argv or sys.argv[1:]
    path = None
    for param in argv:
        if param.startswith('-'):
            pass
        else:
            path = os.path.expanduser(param)
    if not path:
        print('No path supplied! Use %s PATH' % sys.argv[0])
        return 1
    if not os.path.isdir(path):
        print('Path %s does not exist!' % sys.argv[0])
        return 2
    for root, dirs, files in os.walk(path):
        if 'setup' in dirs:
            del dirs[dirs.index('setup')]
        for fn in files:
            if not fn.endswith('.py'):
                continue
            ffn = os.path.join(root, fn)
            do_ren_openerp(ffn)
    return 0


if __name__ == "__main__":
    exit(main(None))
