"""This script prints a timestamp csv in the sample name order as timestamp_1.csv ."""
import sys

def main():
    infile = sys.argv[1]

    samples = []    # copied to spreadsheet in this order
    with open('timestamp_1.csv') as fp:
        table = [x.split(',') for x in fp.read().strip().split('\n')]
        for row in table:
            samples.append(row[3])


    with open(infile) as fp:
        table = [x.split(',') for x in fp.read().strip().split('\n')]
        header = table.pop(0)
        index = header.index('sample_friendly_name')
        for s in samples:
            L = [x for x in table if x[index] == s]
            if L:
                row = L[0]
            else:
                row = [''] * len(header)
                row[index] = s
            print (','.join(row))



if __name__ == '__main__':
    main()
