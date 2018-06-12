// Core Python -> Swift bootstrap
// The vim plugin is expected to call swiftvim_load when
// it's time to initialize the plugin
#include <Python.h>
#include <unistd.h>

// Plugin init is called to bootstrap the plugin in vim
// It should deffinitely return
extern int plugin_init(const char *);
extern const char *plugin_user_event(int, const char *);

static PyObject *swiftvimError;

// Python method `load`
static PyObject * swiftvim_load(PyObject *self, PyObject *args);
static PyObject * swiftvim_event(PyObject *self, PyObject *args);

static PyMethodDef swiftvimMethods[] = {
    {"load",  swiftvim_load, METH_VARARGS,
     "Load the plugin."},

    {"event",  swiftvim_event, METH_VARARGS,
     "Handle a user event."},

    {NULL, NULL, 0, NULL}        /* Sentinel */
};



#if PY_MAJOR_VERSION == 3

static struct PyModuleDef swiftvimmodule = {
    PyModuleDef_HEAD_INIT,
    "swiftvim", /* name of module */
    NULL, /* module documentation, may be NULL */
    -1, /* size of per-interpreter state of the module,
        or -1 if the module keeps state in global variables. */
    swiftvimMethods
};

PyMODINIT_FUNC PyInit_swiftvim(void) {
    PyObject *m;

    m = PyModule_Create(&swiftvimmodule);
    if (m == NULL)
        return NULL;

    swiftvimError = PyErr_NewException("swiftvim.error", NULL, NULL);
    Py_INCREF(swiftvimError);
    PyModule_AddObject(m, "error", swiftvimError);
    return m;
}

#else 

PyMODINIT_FUNC initswiftvim(void) {
    PyObject *m;

    m = Py_InitModule("swiftvim", swiftvimMethods);
    if (m == NULL)
        return;

    swiftvimError = PyErr_NewException("swiftvim.error", NULL, NULL);
    Py_INCREF(swiftvimError);
    PyModule_AddObject(m, "error", swiftvimError);
}
#endif

static int calledPluginInit = 0;

static PyObject *swiftvim_load(PyObject *self, PyObject *args)
{
    int status = 1;
    if (calledPluginInit == 0) {
        status = plugin_init("init");
        calledPluginInit = 1;
    } else {
        fprintf(stderr, "warning: called swiftvim.plugin_init more than once");
    }
    return Py_BuildValue("i", status);
}

static PyObject *swiftvim_event(PyObject *self, PyObject *args)
{
    const char *ctx;
    int event;
    void *result;
    if (!PyArg_ParseTuple(args, "is", &event, &ctx)) {
        fprintf(stderr, "plugin_user_event parsefail");
        result = (void *)plugin_user_event(-1, "error parse");
    } else {
        result = (void *)plugin_user_event(event, ctx);
    }

    return Py_BuildValue("s", result);
}

