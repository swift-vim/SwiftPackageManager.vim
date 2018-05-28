// Core Python -> Swift bootstrap
// The vim plugin is expected to call swiftvim_load when
// it's time to initialize the plugin
#include <Python.h>
#include <unistd.h>

// Plugin init is called to bootstrap the plugin in vim
// It should deffinitely return
extern void plugin_init();

static PyObject *swiftvimError;

// Python method `load`
static PyObject * swiftvim_load(PyObject *self, PyObject *args);

static PyMethodDef swiftvimMethods[] = {
    {"load",  swiftvim_load, METH_VARARGS,
     "Load the plugin."},
    {NULL, NULL, 0, NULL}        /* Sentinel */
};

PyMODINIT_FUNC initswiftvim(void) {
    PyObject *m;

    m = Py_InitModule("swiftvim", swiftvimMethods);
    if (m == NULL)
        return;

    swiftvimError = PyErr_NewException("swiftvim.error", NULL, NULL);
    Py_INCREF(swiftvimError);
    PyModule_AddObject(m, "error", swiftvimError);
}

static PyObject *swiftvim_load(PyObject *self, PyObject *args)
{
    plugin_init();
    return Py_BuildValue("i", 0);
}

