#!/usr/bin/python
# -*- coding: utf-8 -*-
# author:   Jan Hybs


"""https://github.com/x3mSpeedy/Flow123d-python-utils"""

"""
This script is simple iface to coverage_merge_module module.
Script is expected to run as main python file. Script takes arguments from console and calls methods of module.

Usage: coverage_merge_script.py [options] [file1 file2 ... filen]

Options:
  --version             show program's version number and exit
  -h, --help            show this help message and exit
  -o FILE, --output=FILE
                        output file xml name
  -p FILE, --path=FILE  xml location, default current directory
  -l LOGLEVEL, --log=LOGLEVEL
                        Log level DEBUG, INFO, WARNING, ERROR, CRITICAL
  -f, --filteronly      If set all files will be filtered by keep rules
                        otherwise all given files will be merged and filtered.
  -s SUFFIX, --suffix=SUFFIX
                        Additional suffix which will be added to filtered
                        files so they original files can be preserved
  -k NAME, --keep=NAME  preserves only specific packages. e.g.:
                        'python merge.py -k src.la.*'
                        will keep all packgages in folder src/la/ and all
                        subfolders of this folders.
                        There can be mutiple rules e.g.:
                        'python merge.py -k src.la.* -k unit_tests.la.'
                        Format of the rule is simple dot (.) separated names
                        with wildcard (*) allowed, e.g:
                        package.subpackage.*

If no files are specified all xml files in current directory will be selected.
Useful when there is not known precise file name only location
"""

import sys
import os
import xml.etree.ElementTree as ET
import logging
import re

from optparse import OptionParser

# constants
PACKAGES_LIST = 'packages/package'
PACKAGES_ROOT = 'packages'
CLASSES_LIST = 'classes/class'
CLASSES_ROOT = 'classes'
METHODS_LIST = 'methods/method'
METHODS_ROOT = 'methods'
LINES_LIST = 'lines/line'
LINES_ROOT = 'lines'


class CoverageMerge (object):
    def __init__ (self, options, args):
        self.path = options.path
        self.xmlfiles = args
        self.loglevel = getattr (logging, options.loglevel.upper ())
        self.finalxml = os.path.join (self.path, options.filename)
        self.filteronly = options.filteronly
        self.filtersuffix = options.suffix
        self.packagefilters = options.packagefilters

    def execute_merge (self):
        # get arguments
        logging.basicConfig (level=self.loglevel, format='%(levelname)s %(asctime)s: %(message)s', datefmt='%x %X')

        if not self.xmlfiles:
            for filename in os.listdir (self.path):
                if not filename.endswith ('.xml'):
                    continue
                fullname = os.path.join (self.path, filename)
                if fullname == self.finalxml:
                    continue
                self.xmlfiles.append (fullname)

            if not self.xmlfiles:
                print('No xml files found!')
                sys.exit (1)

        else:
            self.xmlfiles = [self.path + filename for filename in self.xmlfiles]

        # prepare filters
        self.prepare_packagefilters ()

        if self.filteronly:
            # filter all given files
            currfile = 1
            totalfiles = len (self.xmlfiles)
            for xmlfile in self.xmlfiles:
                xml = ET.parse (xmlfile)
                self.filter_xml (xml)
                logging.debug ('{1}/{2} filtering: {0}'.format (xmlfile, currfile, totalfiles))
                xml.write (xmlfile + self.filtersuffix, encoding="UTF-8", xml_declaration=True)
                currfile += 1
        else:
            # merge all given files
            totalfiles = len (self.xmlfiles)

            # special case if only one file was given
            # filter given file and save it
            if (totalfiles == 1):
                logging.warning ('Only one file given!')
                xmlfile = self.xmlfiles.pop (0)
                xml = ET.parse (xmlfile)
                self.filter_xml (xml)
                xml.write (self.finalxml, encoding="UTF-8", xml_declaration=True)
                sys.exit (0)

            currfile = 1
            logging.debug (
                '{2}/{3} merging: {0} & {1}'.format (self.xmlfiles[0], self.xmlfiles[1], currfile, totalfiles - 1))
            self.merge_xml (self.xmlfiles[0], self.xmlfiles[1], self.finalxml)

            currfile = 2
            for i in range (totalfiles - 2):
                xmlfile = self.xmlfiles[i + 2]
                logging.debug ('{2}/{3} merging: {0} & {1}'.format (self.finalxml, xmlfile, currfile, totalfiles - 1))
                self.merge_xml (self.finalxml, xmlfile, self.finalxml)
                currfile += 1

    def merge_xml (self, xmlfile1, xmlfile2, outputfile):
        # parse
        xml1 = ET.parse (xmlfile1)
        xml2 = ET.parse (xmlfile2)

        # get packages
        packages1 = self.filter_xml (xml1)
        packages2 = self.filter_xml (xml2)

        # find root
        packages1root = xml1.find (PACKAGES_ROOT)


        # merge packages
        self.merge (packages1root, packages1, packages2, 'name', self.merge_packages)

        # write result to output file
        xml1.write (outputfile, encoding="UTF-8", xml_declaration=True)


    def filter_xml (self, xmlfile):
        xmlroot = xmlfile.getroot ()
        packageroot = xmlfile.find (PACKAGES_ROOT)
        packages = xmlroot.findall (PACKAGES_LIST)

        # delete nodes from tree AND from list
        included = []
        if self.packagefilters:
            logging.debug ('excluding packages:')
        for pckg in packages:
            name = pckg.get ('name')
            if not self.include_package (name):
                logging.debug ('excluding package "{0}"'.format (name))
                packageroot.remove (pckg)
            else:
                logging.debug ('preserving package "{0}"'.format (name))
                included.append (pckg)
        return included

    def prepare_packagefilters (self):
        if not self.packagefilters:
            return None

        # create simple regexp from given filter
        for i in range (len (self.packagefilters)):
            self.packagefilters[i] = '^' + self.packagefilters[i].replace ('.', '\.').replace ('*', '.*') + '$'

    def include_package (self, name):
        if not self.packagefilters:
            return True

        for packagefilter in self.packagefilters:
            if re.search (packagefilter, name):
                return True
        return False

    def get_attributes_chain (self, obj, attrs):
        """Return a joined arguments of object based on given arguments"""

        if type (attrs) is list:
            result = ''
            for attr in attrs:
                result += obj.attrib[attr]
            return result
        else:
            return obj.attrib[attrs]

    def merge (self, root, list1, list2, attr, merge_function):
        """ Groups given lists based on group attributes. Process of merging items with same key is handled by
            passed merge_function. Returns list1. """
        for item2 in list2:
            found = False
            for item1 in list1:
                if self.get_attributes_chain (item1, attr) == self.get_attributes_chain (item2, attr):
                    item1 = merge_function (item1, item2)
                    found = True
                    break
            if found:
                continue
            else:
                root.append (item2)

    def merge_packages (self, package1, package2):
        """Merges two packages. Returns package1."""
        classes1 = package1.findall (CLASSES_LIST)
        classes2 = package2.findall (CLASSES_LIST)
        if classes1 or classes2:
            self.merge (package1.find (CLASSES_ROOT), classes1, classes2, ['filename', 'name'], self.merge_classes)

        return package1

    def merge_classes (self, class1, class2):
        """Merges two classes. Returns class1."""

        lines1 = class1.findall (LINES_LIST)
        lines2 = class2.findall (LINES_LIST)
        if lines1 or lines2:
            self.merge (class1.find (LINES_ROOT), lines1, lines2, 'number', self.merge_lines)

        methods1 = class1.findall (METHODS_LIST)
        methods2 = class2.findall (METHODS_LIST)
        if methods1 or methods2:
            self.merge (class1.find (METHODS_ROOT), methods1, methods2, 'name', self.merge_methods)

        return class1

    def merge_methods (self, method1, method2):
        """Merges two methods. Returns method1."""

        lines1 = method1.findall (LINES_LIST)
        lines2 = method2.findall (LINES_LIST)
        self.merge (method1.find (LINES_ROOT), lines1, lines2, 'number', self.merge_lines)

    def merge_lines (self, line1, line2):
        """Merges two lines by summing their hits. Returns line1."""

        # merge hits
        value = int (line1.get ('hits')) + int (line2.get ('hits'))
        line1.set ('hits', str (value))

        # merge conditionals
        con1 = line1.get ('condition-coverage')
        con2 = line2.get ('condition-coverage')
        if con1 is not None and con2 is not None:
            con1value = int (con1.split ('%')[0])
            con2value = int (con2.split ('%')[0])
            # bigger coverage on second line, swap their conditionals
            if con2value > con1value:
                line1.set ('condition-coverage', str (con2))
                line1.__setitem__ (0, line2.__getitem__ (0))

        return line1


def merge (options, args):
    """Simple iface method for c api"""
    return CoverageMerge (options, args).execute_merge ()

# parse arguments
def create_parser ():
    """Creates command line parse"""
    newline = 10 * '\t';
    parser = OptionParser (usage="%prog [options] [file1 file2 ... filen]", version="%prog 1.0",
                           epilog="If no files are specified all xml files in current directory will be selected. \n" +
                                  "Useful when there is not known precise file name only location")

    parser.add_option ("-o", "--output", dest="filename", default="coverage-merged.xml",
                       help="output file xml name", metavar="FILE")
    parser.add_option ("-p", "--path", dest="path", default="./",
                       help="xml location, default current directory", metavar="FILE")
    parser.add_option ("-l", "--log", dest="loglevel", default="WARNING",
                       help="Log level DEBUG, INFO, WARNING, ERROR, CRITICAL")
    parser.add_option ("-f", "--filteronly", dest="filteronly", default=False, action='store_true',
                       help="If set all files will be filtered by keep rules otherwise " +
                            "all given files will be merged and filtered.")
    parser.add_option ("-s", "--suffix", dest="suffix", default='',
                       help="Additional suffix which will be added to filtered files so they original files can be preserved")
    parser.add_option ("-k", "--keep", dest="packagefilters", default=None, metavar="NAME", action="append",
                       help="preserves only specific packages. e.g.: " + newline +
                            "'python merge.py -k src.la.*'" + newline +
                            "will keep all packgages in folder " +
                            "src/la/ and all subfolders of this folders. " + newline +
                            "There can be mutiple rules e.g.:" + newline +
                            "'python merge.py -k src.la.* -k unit_tests.la.'" + newline +
                            "Format of the rule is simple dot (.) separated names with wildcard (*) allowed, e.g: " + newline +
                            "package.subpackage.*")
    return parser


def parse_args (parser):
    """Parses argument using given parses and check resulting value combination"""
    (options, args) = parser.parse_args ()

    # for now, no check needed

    return (options, args)


if __name__ == '__main__':
    parser = create_parser ()
    (options, args) = parse_args (parser)

    merge (options, args)