/*/-----------------------------------------------------------------------
//-- Matlab Script created coefficients file
//-- Matlab Script Author Alexander Lindert 
//----------------------------------------------------------------------*/
#include  "types.h"            
#define  POLYPHASES           8
#define  POLYPHASE_COEFFS     6
#define  FILTER_COEFFS       48
#define  DOWNSHIFT           16

#pragma WARNING OFF
const int32_t  Filter_I8[8][6] =
{{ 0, 0, 0, 32734, 0, 0}, 
{ 167, -1037, 3988, 31700, -2648, 623}, 
{ 419, -2278, 8934, 28922, -4115, 930}, 
{ 718, -3521, 14462, 24721, -4529, 966}, 
{ 993, -4494, 20068, 19566, -4129, 816}, 
{ 1151, -4887, 25192, 14008, -3205, 574}, 
{ 1088, -4403, 29287, 8596, -2053, 323}, 
{ 718, -2812, 31900, 3810, -924, 123}};
#pragma WARNING ON
