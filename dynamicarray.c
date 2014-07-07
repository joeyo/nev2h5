#include "dynamicarray.h"
#include <stdio.h>
#include <stdlib.h>

DynamicArray *new_dynamic_array(uint32_t init_size){
    DynamicArray *array;
    void *_temp = malloc(sizeof(DynamicArray));
    if (!_temp){
        fprintf(stderr, "ERROR: can't build dynamic array!\n");
        return(NULL);
    }
    array = (DynamicArray*)_temp;
    _temp = malloc(init_size * sizeof(uint32_t));
    if (!_temp){
        fprintf(stderr, "ERROR: can't initialize dynamic array!\n");
        return(NULL);
    }
    array->array = (uint32_t*)_temp;
    array->used_length = 0;
    array->allocated = init_size;
    return array;
}

void dynamic_array_free(DynamicArray *array, uint8_t owned){
    if (owned > 0) free(array->array);
    free(array);
    return;
}

uint32_t dynamic_array_size_of(DynamicArray *array){
    return array->used_length;
}

int dynamic_array_add(DynamicArray *array, uint32_t value){
   if (array->used_length == array->allocated){
        if (array->allocated == 0)
            array->allocated = 128;
        else
            array->allocated *= 2;

        void *_temp = realloc(array->array, (array->allocated * sizeof(uint32_t)));
        if (!_temp){
            fprintf(stderr, "used: %u, size: %u ERROR: can't realloc memory to dynamic array!\n", array->used_length, array->allocated);
            return(-1);
        }
        array->array = (uint32_t*)_temp;
   }
   array->array[array->used_length] = value;
   ++(array->used_length);

   return 0;
}

uint32_t dynamic_array_get(DynamicArray *array, uint32_t index){
    if (index < array->used_length) 
        return array->array[index];
    else
        fprintf(stderr, "index out of bounds! %u in array %u long.", index, array->used_length);
        return(-1);
}

void dynamic_array_set(DynamicArray *array, uint32_t index, uint32_t value) {
    if (index < array->used_length) array->array[index] = value;
    return;
}

int dynamic_array_copy(DynamicArray *from, DynamicArray *to) {
    to->used_length = 0;
    for (int idx = 0; idx < dynamic_array_size_of(from); ++idx) {
        dynamic_array_add(to, dynamic_array_get(from, idx));
    }
    return 0;
}
