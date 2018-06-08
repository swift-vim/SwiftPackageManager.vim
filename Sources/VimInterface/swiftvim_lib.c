#include <Python.h>
#include <unistd.h>

/// Bridge PyString_AsString to both runtimes
static const char *SPyString_AsString(PyObject *input) {
#if PY_MAJOR_VERSION == 3
    // FIXME:
    // https://stackoverflow.com/questions/6783493/python-unicode-object-and-c-api-retrieving-char-from-pyunicode-objects
    return (const char *)PyUnicode_AsUnicode(input);
#else
    return PyString_AsString(input);
#endif
}

/// Bridge PyString_FromString to both runtimes
static PyObject *SPyString_FromString(const char *input) {
#if PY_MAJOR_VERSION == 3
    return PyUnicode_FromString(input);
#else
    return PyString_FromString(input);
#endif
}

// module=vim, method=command|exec, str = value
void *swiftvim_call(const char *module, const char *method, const char *textArg) {
    PyGILState_STATE gstate = PyGILState_Ensure();

    // FIXME: we shouldn't need to always import
    PyObject *pName = SPyString_FromString(module);
    PyObject *pModule = PyImport_Import(pName);
    Py_DECREF(pName);
    if (pModule == NULL) {
        PyErr_Print();
        fprintf(stderr, "swiftvim error: failed to load \"%s\"\n", module);
        return NULL;
    }

    void *outValue = NULL;
    PyObject *pFunc = PyObject_GetAttrString(pModule, method);
    // pFunc is a new reference 
    if (pFunc && PyCallable_Check(pFunc)) {
        PyObject *pArgs = PyTuple_New(1);
        PyObject *pValue = SPyString_FromString(textArg);
        if (!pValue) {
            Py_DECREF(pArgs);
            Py_DECREF(pModule);
            fprintf(stderr, "swiftvim error: Cannot convert argument\n");
            return NULL;
        }
        int argOffset = 0;
        PyTuple_SetItem(pArgs, argOffset, pValue);
        pValue = PyObject_CallObject(pFunc, pArgs);
        Py_DECREF(pArgs);
        if (pValue != NULL) {
            outValue = pValue;
        } else {
            Py_DECREF(pFunc);
            Py_DECREF(pModule);
            PyErr_Print();
            fprintf(stderr,"swiftvim error: call failed\n");
            return outValue;
        }
    } else {
        if (PyErr_Occurred())
            PyErr_Print();
        fprintf(stderr, "swiftvim error: cannot find function \"%s\"\n", method);
    }

    PyGILState_Release(gstate);
    Py_XDECREF(pFunc);
    Py_DECREF(pModule);
    return outValue;
}

void *swiftvim_command(const char *command) {
    return swiftvim_call("vim", "command", command);
}

void *swiftvim_eval(const char *eval) {
    return swiftvim_call("vim", "eval", eval);
}

// TODO: Do these need GIL locks?
void *swiftvim_decref(void *value) {
    Py_DECREF(value);
    return value;
}

void *swiftvim_incref(void *value) {
    Py_INCREF(value);
    return value;
}

const char *swiftvim_asstring(void *value) {
    if (value == NULL) {
        return "";
    }
    PyGILState_STATE gstate = PyGILState_Ensure();
    const char *v = SPyString_AsString(value);
    PyGILState_Release(gstate);
    return v;
}

int swiftvim_asint(void *value) {
    PyGILState_STATE gstate = PyGILState_Ensure();
    int v = PyLong_AsLong(value);
    PyGILState_Release(gstate);
    return v;
}

void swiftvim_initialize() {
    Py_Initialize();
    if(!PyEval_ThreadsInitialized()) {
        PyEval_InitThreads();
    }

#ifdef SPMVIM_LOADSTUB_RUNTIME
    // For unit tests, we fake out the vim module
    // to make the tests as pure as possible.
    // Assume that tests are running from the source root
    // We could do something better.
    char cwd[1024];
    if (getcwd(cwd, sizeof(cwd)) == NULL)
        fprintf(stderr, "GarbPWD");
    strcat(cwd, "/Tests/VimInterfaceTests/MockVimRuntime/");
    fprintf(stderr, "Adding test import path: %s \n", cwd);
    PyObject* sysPath = PySys_GetObject((char*)"path");
    PyObject* programName = SPyString_FromString(cwd);
    PyList_Append(sysPath, programName);
    Py_DECREF(programName);
#endif
}

void swiftvim_finalize() {
    Py_Finalize();
}

