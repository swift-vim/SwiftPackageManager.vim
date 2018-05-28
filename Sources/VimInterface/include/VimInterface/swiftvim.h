// Main vimscript methods
void *swiftvim_command(const char *command);
void *swiftvim_expr(const char *expr);

// Internally, the API uses reference counting
void *swiftvim_decref(void *value); 
void *swiftvim_incref(void *value);

// Value extraction
const char *swiftvim_asstring(void *value);
int swiftvim_asint(void *value);

// Bootstrapping
// Note: These methods are only for testing purposes
void swiftvim_initialize();
void swiftvim_finalize();
void *swiftvim_call(const char *module, const char *method, const char *str); 

