#!/bin/env python3

from pathlib import Path, PurePath
import sys
import filecmp
import argparse
import vimrunner

# arg parsing
parser = argparse.ArgumentParser(description='Run test suite. See README.')
parser.add_argument('test', nargs='?', help='run <test> only instead of running all tests')
parser.add_argument('-l', '--list', action='store_true', help='list all tests')
args = parser.parse_args()


def print_banner(string):
    print("""
#--------------------------------------------------------------
# %s
#--------------------------------------------------------------""" % string)


def run_one_test(test):
    global failing_tests
    print_banner(test)
    print("reproduce: ./test.py " + test)
    # input/output files
    try:
        vimrc_path = Path('tests/', test, 'vimrc.vim').resolve(strict=True)
    except FileNotFoundError:
        vimrc_path = Path('default/', 'vimrc.vim').resolve(strict=True)
        print("using default vimrc")
    command_path = Path('tests/', test, 'commands.py').resolve(strict=True)
    in_file_path = Path('tests/', test, 'input_file.txt').resolve(strict=True)
    exp_out_file_path = Path('tests/', test, 'expected_output_file.txt').resolve(strict=True)
    gen_out_file_path = Path('tests/', test, 'generated_output_file.txt').resolve()
    # run test
    vim = vimrunner.Server(noplugin=False, vimrc=vimrc_path)
    client = vim.start()
    client.edit(in_file_path)
    exec(open(command_path).read())
    client.feedkeys(':wq! %s\<CR>' % gen_out_file_path)
    # check results
    if filecmp.cmp(exp_out_file_path, gen_out_file_path):
        print("SUCCESS")
    else:
        failing_tests.append(test)
        print("FAIL")


# execution
failing_tests = []
tests = [str(p).replace('tests/','') for p in Path('tests').glob('*')]
if args.list:
    print("\n".join(tests))
else:
    if args.test is not None:
        run_one_test(args.test)
    else:
        for test in tests:
            run_one_test(test)
    if failing_tests == []:
        print_banner("summary: SUCCESS")
    else:
        print_banner("summary: FAIL")
        print("the following tests failed:")
        print("\n".join(failing_tests))
        sys.exit(1)
