from matplotlib import pyplot as plt
import numpy as np

x = np.linspace(-10, 10, 1000)


def plot_function(function_name, y):
    plt.figure()
    plt.plot(x, y)
    plt.xlabel('x')
    plt.ylabel('y = ' + function_name)
    plt.savefig(function_name + '.svg', format='svg', dpi=1000)


plot_function('Sigmoid(x)', y=[1 / (1 + np.exp(-m)) for m in x])
plot_function('Tanh(x)', y=np.tanh(x))
plot_function('ReLU(x)', y=[max(0, m) for m in x])
