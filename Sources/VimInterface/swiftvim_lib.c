#include <Python.h>
#include <unistd.h>

// module=vim, method=command|exec, str = value
void *swiftvim_call(const char *module, const char *method, const char *str) {
    PyObject *pName, *pModule, *pDict, *pFunc;
    PyObject *pArgs, *pValue;

    pName = PyString_FromString(module);
    /* Error checking of pName left out */

    pModule = PyImport_Import(pName);
    Py_DECREF(pName);

    if (pModule == NULL) {
        PyErr_Print();
        fprintf(stderr, "Failed to load \"%s\"\n", module);
        return NULL;
    }

    void *outValue = NULL;
    pFunc = PyObject_GetAttrString(pModule, method);
    // pFunc is a new reference 
    if (pFunc && PyCallable_Check(pFunc)) {
        pArgs = PyTuple_New(1);
        pValue = PyString_FromString(str);
        if (!pValue) {
            Py_DECREF(pArgs);
            Py_DECREF(pModule);
            fprintf(stderr, "Cannot convert argument\n");
            return NULL;
        }

        int argOffset = 0;
        PyTuple_SetItem(pArgs, argOffset, pValue);
        pValue = PyObject_CallObject(pFunc, pArgs);
        Py_DECREF(pArgs);
        if (pValue != NULL) {

#ifdef SPMVIM_PY_DEBUG
            printf("Result of call: %ld\n", PyInt_AsLong(pValue));
#endif
            outValue = pValue;
        } else {
            Py_DECREF(pFunc);
            Py_DECREF(pModule);
            PyErr_Print();
            fprintf(stderr,"Call failed\n");
            return outValue;
        }
    } else {
        if (PyErr_Occurred())
            PyErr_Print();
        fprintf(stderr, "Cannot find function \"%s\"\n", method);
    }
    Py_XDECREF(pFunc);
    Py_DECREF(pModule);
    return outValue;
}

void *swiftvim_command(const char *command) {
    return swiftvim_call("vim", "command", command);
}

void *swiftvim_expr(const char *command) {
    return swiftvim_call("vim", "expr", command);
}

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
    return PyString_AsString(value);
}

int swiftvim_asint(void *value) {
    return PyInt_AsLong(value);
}

void swiftvim_initialize() {
    Py_Initialize();
    // For unit tests, we fake out the vim module
    // to make the tests as pure as possible.
#ifdef SPMVIM_LOADSTUB_RUNTIME
    // Assume that tests are running from the source root
    // We could do something better.
    char cwd[1024];
    if (getcwd(cwd, sizeof(cwd)) == NULL)
        fprintf(stderr, "GarbPWD");
    strcat(cwd, "/Tests/VimInterfaceTests/MockVimRuntime/");
    fprintf(stderr, "Adding test import path: %s \n", cwd);
    PyObject* sysPath = PySys_GetObject((char*)"path");
    PyObject* programName = PyString_FromString(cwd);
    PyList_Append(sysPath, programName);
    Py_DECREF(programName);
#endif
}

void swiftvim_finalize() {
    Py_Finalize();
}

