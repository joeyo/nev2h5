#ifndef DYNAMIC_ARRAY
#define DYNAMIC_ARRAY
#include <stdint.h>
typedef struct dynamic_array_{
    uint32_t allocated;   /* keep track of allocated size  */
    uint32_t used_length;  /* keep track of usage           */
    uint32_t *array;      /* dynamicaly grown with realloc */
} DynamicArray;

DynamicArray *new_dynamic_array(uint32_t init_size);
void dynamic_array_free(DynamicArray *array, uint8_t owned);
uint32_t dynamic_array_size_of(DynamicArray *array);
int dynamic_array_add(DynamicArray *array, uint32_t value);
uint32_t dynamic_array_get(DynamicArray *array, uint32_t index);
int dynamic_array_copy(DynamicArray *from, DynamicArray *to);
void dynamic_array_set(DynamicArray *array, uint32_t index, uint32_t value);
#endif

