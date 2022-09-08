from pulsar import Function

class ExclamationFunction(Function):
    def __init__(self):
        pass

    def process(self, input, context):
        print("input %s" % input)
        print("context %s" % context)
        return "{}!".format(input)