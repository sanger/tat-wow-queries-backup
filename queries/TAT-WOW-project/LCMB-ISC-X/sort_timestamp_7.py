"""This script prints timestamp_7.csv in the sample_name order as timestamp_1.csv ."""

def main():
    samples = []    # copied to spreadsheet in this order
    with open('timestamp_1.csv') as fp:
        table = [x.split(',') for x in fp.read().strip().split('\n')]
        for row in table:
            samples.append(row[3])

    def sorter(x):
        return samples.index(x[2])  # zero-based index of sample_name

    with open('timestamp_7.csv') as fp:
        table = [x.split(',') for x in fp.read().strip().split('\n')]
        header = table.pop(0)
        table.sort(key=sorter)
        table.insert(0, header)
        print ('\n'.join([','.join(x) for x in table]))

if __name__ == '__main__':
    main()
