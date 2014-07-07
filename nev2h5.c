/* heaving lifting in reading Blackrock .nev file */
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include "hdf5.h"
#include "hdf5_hl.h"

#include "dynamicarray.h"

#define PACKET_SIZE_RESERVE (94)

const int BUFFER_SIZE = 128;
const int EVENT_TYPES = 32;
const int MAX_CHANNEL = 196;
const int MAX_UNITS = 8;

typedef struct NEV_Header_ {
    char fileTypeId[8];
    unsigned char fileSpec[2];
    uint16_t additionalFlags;
    uint32_t bytesInHeader;
    uint32_t bytesInPacket;
    uint32_t timestampResolution;
    uint32_t sampleResolution;
    uint16_t timeOrigin[8];
    char createrApp[32];
    char comment[256];
    uint32_t extendedHeaderNumber;
} NEV_Header;

typedef struct NEV_EVWAV_ {
    uint16_t electrodeId;
    unsigned char physicalConnector;
    unsigned char connectorPin;
    uint16_t digitizationFactor;
    uint16_t energyThreshold;
    int16_t highThreshold;
    int16_t lowThreshold;
    unsigned char sortedUnitsNumber;
    unsigned char bytesPerWaveformSample;
    uint16_t spikeWidth;
    char reserved[8];
} NEV_EVWAV;

static int read_header(FILE *ptr_nev, hid_t ptr_h5, uint8_t *bytesInPacket) {
    NEV_Header header;

    if (!fread(&header, sizeof(NEV_Header), 1, ptr_nev)) return -1;
    *bytesInPacket = header.bytesInPacket;
    fprintf(stdout, "\nThe packet size in this file is %u\n", *bytesInPacket);
    fprintf(stdout, "The script was compiled with PACK_SIZE = %d\n", PACKET_SIZE_RESERVE + 10);
    char iso8601_str[24];
    uint16_t *timeOrigin = header.timeOrigin;
    int sampleResolution = (int)header.sampleResolution;
    sprintf(iso8601_str, "%04u-%02u-%02uT%02u:%02u:%02u.%03u",
            timeOrigin[0], timeOrigin[1], timeOrigin[3], timeOrigin[4],
            timeOrigin[5], timeOrigin[6], timeOrigin[7]);
    H5LTset_attribute_string(ptr_h5, "/", "timeOrigin", iso8601_str);
    H5LTset_attribute_uint(ptr_h5, "/", "resolution", &sampleResolution, 1);
    H5LTset_attribute_string(ptr_h5, "/", "comment", header.comment);

    NEV_EVWAV channelInfo;
    char packetType[9];
    packetType[8] = '\0';
    char strBuffer[25];
    strBuffer[24] = '\0';
    char electrodeId[4];
    hid_t channels, channel;
    channels = H5Gcreate(ptr_h5, "/channels", H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);

    for (int i = 0; i < header.extendedHeaderNumber; i++) {
        if (!fread(packetType, sizeof(char), 8, ptr_nev)) return -1;
        if (strcmp(packetType, "NEUEVWAV") == 0) {
            if (!fread(&channelInfo, sizeof(NEV_EVWAV), 1, ptr_nev)) return -2;
            sprintf(electrodeId, "%03u", channelInfo.electrodeId);
            channel = H5Gcreate(channels, electrodeId, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT); 
            int physicalConnector = (int)channelInfo.physicalConnector;
            H5LTset_attribute_int(channels, electrodeId, "physicalConnector", &physicalConnector, 1);
            int connectorPin = (int)channelInfo.connectorPin;
            H5LTset_attribute_int(channels, electrodeId, "connectorPin", &connectorPin, 1);
            int digitizationFactor = (int)channelInfo.digitizationFactor;
            H5LTset_attribute_int(channels, electrodeId, "digitizationFactor", &digitizationFactor, 1);
            int energyThreshold = (int)channelInfo.energyThreshold;
            H5LTset_attribute_int(channels, electrodeId, "energyThreshold", &energyThreshold, 1);
            int highThreshold = (int)channelInfo.highThreshold;
            H5LTset_attribute_int(channels, electrodeId, "highThreshold", &highThreshold, 1);
            int lowThreshold = (int)channelInfo.lowThreshold;
            H5LTset_attribute_int(channels, electrodeId, "lowThreshold", &lowThreshold, 1);
            int sortedUnitsNumber = (int)channelInfo.sortedUnitsNumber;
            H5LTset_attribute_int(channels, electrodeId, "sortedUnitsNumber", &sortedUnitsNumber, 1);
            int bytesPerWaveformSample = (int)channelInfo.bytesPerWaveformSample;
            H5LTset_attribute_int(channels, electrodeId, "bytesPerWaveformSample", &bytesPerWaveformSample, 1);
            int spikeWidth = (int)channelInfo.spikeWidth;
            H5LTset_attribute_int(channels, electrodeId, "spikeWidth", &spikeWidth, 1);
            H5Gclose(channel);
        } else if (strcmp(packetType, "MAPFILE") == 0) {
            if (!fread(strBuffer, sizeof(char), 24, ptr_nev)) return -3;
            H5LTset_attribute_string(ptr_h5, "/", "mapfile", strBuffer);
        } else if (strcmp(packetType, "ARRAYNME") == 0) {
            if (!fread(strBuffer, sizeof(char), 24, ptr_nev)) return -4;
            H5LTset_attribute_string(ptr_h5, "/", "arrayName", strBuffer);
        } else {
            fseek(ptr_nev, 24, SEEK_CUR);
        }
    }
    H5Fflush(ptr_h5, H5F_SCOPE_GLOBAL);
    H5Gclose(channels);
    return 0;
}

typedef struct NEV_DataPacket_ {
    uint32_t timestamp;
    uint16_t packet_id;
    unsigned char classification;
    unsigned char unit_reserved;
    uint16_t digital_input;
    char reserve[PACKET_SIZE_RESERVE];
} NEV_DataPacket;

static int read_data(FILE *ptr_nev, hid_t ptr_h5, uint8_t bytesInPacket) {
    /* write the main section of Blackrock .nev file (version 2.0-2.3) to hdf5
     * Args:
     *      ptr_nev: pointer to the opened .nev file
     * Return:
     *      0 for success and non-zero for error
     *      (spike_trains, events) where
     *          spike_trains: dict (of channels) of dicts (of units) of 1D numpy
     *              array of uint32 (timestamp)
     *          events: dict (of markers) of 1D numpy array of uint32_t (timestamp)
     * */

    DynamicArray *spike_trains[MAX_CHANNEL][MAX_UNITS];
    for (int i = 0; i < MAX_CHANNEL; ++i) {
        for (int j = 0; j < MAX_UNITS; ++j) {
            spike_trains[i][j] = new_dynamic_array(0);
        }
    }
    DynamicArray *events = new_dynamic_array(128);
    DynamicArray *markers = new_dynamic_array(128);

    NEV_DataPacket dataPackets[BUFFER_SIZE];
    uint32_t data_start = (uint32_t)ftell(ptr_nev);
    fseek(ptr_nev, 0, SEEK_END);
    uint32_t data_end = (uint32_t)ftell(ptr_nev);
    fseek(ptr_nev, data_start, SEEK_SET);
    uint32_t packetNumber = (data_end - data_start) / bytesInPacket;

    for (uint32_t i = 0; i < packetNumber / BUFFER_SIZE; i++) {
        if (!fread(&dataPackets, bytesInPacket, BUFFER_SIZE, ptr_nev)) {
            return -1;
        }
        for (uint32_t j = 0; j < BUFFER_SIZE; j++) {
            if (dataPackets[j].packet_id == 0) {
                dynamic_array_add(events, dataPackets[j].timestamp);
                dynamic_array_add(markers, dataPackets[j].digital_input);
            } else if ((dataPackets[j].classification < MAX_UNITS) && (dataPackets[j].packet_id < MAX_CHANNEL)) {
                dynamic_array_add(spike_trains[dataPackets[j].packet_id][dataPackets[j].classification], dataPackets[j].timestamp);
            }
        }
    }
    uint32_t leftOver = packetNumber % BUFFER_SIZE;
    if (!fread(&dataPackets, bytesInPacket, leftOver, ptr_nev)) {
        return -1;
    }
    for (uint32_t i = 0; i < leftOver; i++) {
        if (dataPackets[i].packet_id == 0) {
            dynamic_array_add(events, dataPackets[i].timestamp);
            dynamic_array_add(markers, dataPackets[i].digital_input);
        } else if ((dataPackets[i].classification < MAX_UNITS) && (dataPackets[i].packet_id < MAX_CHANNEL)) {
            dynamic_array_add(spike_trains[dataPackets[i].packet_id][dataPackets[i].classification], dataPackets[i].timestamp);
        }
    }

    // start writing data to ptr_h5 file 

    // First the spike trains
    // find non-empty spike_trains
    hsize_t dims[1];
    char electrodeId[4];
    char unitId[4];
    hid_t channels = H5Gopen(ptr_h5, "/channels", H5P_DEFAULT);
    for (int i = 0; i < MAX_CHANNEL; ++i) {
        unsigned char channel_used = 0;
        sprintf(electrodeId, "%03u", i);
        if (!H5Lexists(channels, electrodeId, H5P_DEFAULT)) {
            for (int j = 0; j < 8; ++j) dynamic_array_free(spike_trains[i][j], 1);
            continue;
        }
        hid_t channel = H5Gopen(channels, electrodeId, H5P_DEFAULT);
        for (int j = 0; j < 8; ++j) {
            DynamicArray *train = spike_trains[i][j];
            if (dynamic_array_size_of(train) > 0) {
                channel_used = 1;
                dims[0] = dynamic_array_size_of(train);
                sprintf(unitId, "%01d", j);
                H5LTmake_dataset_int(channel, unitId, 1, dims, train->array);
                dynamic_array_free(train, 0);
            } else {
                dynamic_array_free(train, 1);
            }
        }
        H5Gclose(channel);
        if (!channel_used) {
            H5Ldelete(channels, electrodeId, H5P_DEFAULT);
        }
    }
    H5Gclose(channels);

    // Then events
    char eventId[4];
    DynamicArray *marker_stamps[EVENT_TYPES];
    hid_t h5_events = H5Gcreate(ptr_h5, "events", H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
    for (int i = 0; i < EVENT_TYPES; i++) marker_stamps[i] = new_dynamic_array(0);
    for (long i = 0; i < dynamic_array_size_of(markers); ++i) {
        int marker = dynamic_array_get(markers, i);
        if (marker >= EVENT_TYPES) continue;
        dynamic_array_add(marker_stamps[marker], dynamic_array_get(events, i));
    }
    for (int i = 0; i < EVENT_TYPES; i++) {
        if (dynamic_array_size_of(marker_stamps[i]) > 0) {
            sprintf(eventId, "%02d", i);
            dims[0] = dynamic_array_size_of(marker_stamps[i]);
            H5LTmake_dataset_int(h5_events, eventId, 1, dims, marker_stamps[i]->array);
            dynamic_array_free(marker_stamps[i], 0);
        } else {
            dynamic_array_free(marker_stamps[i], 1);
        }
    }
    H5Fflush(ptr_h5, H5F_SCOPE_GLOBAL);
    H5Gclose(h5_events);
    return 0;
}

const char usage[] = "nev2h5 NEV_PATH[ H5_PATH]\n"
                     "\tNEV_PATH: relative or full path of the input .nev file\n"
                     "\tH5_PATH: relative or full path of the output .h5 file\n";

int main(int argc, char *argv[]) {
    // get nev_name and h5_name
    char args[2][1024];
    if (argc != 3) {
        fprintf(stderr, usage);
        return -1;
    }
    char cwd[1024];
    if (getcwd(cwd, sizeof(cwd)) == NULL) {
       fprintf(stderr, "getcwd() error");
       return -1;
    }
    for (int i = 0; i < 2; i++) {
        if (argv[i][0] != '/') {
            strcpy(args[i], cwd);
            strcat(args[i], "/");
            strcat(args[i], argv[i + 1]);
        } else {
            strcpy(args[i], argv[i + 1]);
        }
    }
    char *nev_name = args[0];
    char *h5_name = args[1];
    
    // open .nev file
    FILE *ptr_nev;
    if (!(ptr_nev = fopen(nev_name, "rb"))) {
        fprintf(stderr, "nev file open error! %s\n", nev_name);
        return 1;
    }
    hid_t ptr_h5;
    ptr_h5 = H5Fcreate(h5_name, H5F_ACC_EXCL, H5P_DEFAULT, H5P_DEFAULT);
    uint8_t bytesInPacket;
    int errno = read_header(ptr_nev, ptr_h5, &bytesInPacket);
    if (errno) {
        fprintf(stderr, "something wrong reading header. code: %d", errno);
        return -1;
    }
    read_data(ptr_nev, ptr_h5, bytesInPacket);
    fclose(ptr_nev);
    
    H5Fclose(ptr_h5);
    return 0;
}
