// Copyright 2023 StarkWare Industries Ltd.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.starkware.co/open-source-license/
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions
// and limitations under the Licenser

%builtins output


from starkware.cairo.common.segments import relocate_segment
from starkware.cairo.common.serialize import serialize_word

func main(output_ptr: felt*) -> (output_ptr: felt*) {
    alloc_locals;


    local a = 2;
    local b = 2;
    local c = a*b + b;
    local d = c + b;
    local e = a + b;


    assert output_ptr[0] = 1;
    assert output_ptr[1] = c;



    assert output_ptr[2] = 7;


    // Return the updated output_ptr.
    return (output_ptr=&output_ptr[3]);
}

// Serializes to output the constant-sized execution info needed for the L1 state 