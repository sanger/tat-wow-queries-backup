
import sys

def main():
    infile = sys.argv[1]

    samples = []    # copied to spreadsheet in this order
    with open('timestamp_1.csv') as fp:
        table = [x.split(',') for x in fp.read().strip().split('\n')]
        for row in table:
            samples.append(row[3])


    # ewh_sample_id,sample_uuid_bin,sample_uuid,sample_friendly_name,reisc_event_id,ReISC_order_made
    with open(infile) as fp:
        table = [x.split(',') for x in fp.read().strip().split('\n')]
        header = table.pop(0)
        index = header.index('sample_friendly_name')
        def sorter(x):
            return samples.index(x[index])  # zero-based index of sample_name
        table.sort(key=sorter)
        # print(','.join(header))
        empty = ',' * (len(header)-1)
        for s in samples:
            L = [x for x in table if x[3] == s]
            if L:
                L = L[0]
                print(','.join(L))
            else:
                print(empty)

if __name__ == '__main__':
    main()
