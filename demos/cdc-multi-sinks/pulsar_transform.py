from pulsar import Function

class ExclamationFunction(Function):
    def __init__(self, a, b):
        self.a = a
        self.b = b

    def process(self, input, context):
        print(40 * '$')
        print(type(input))
        print(input)
        print(40 * '$')
        return "{}!".format(input)