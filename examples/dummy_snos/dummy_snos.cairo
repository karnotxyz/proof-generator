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

    assert output_ptr[0] = 1;
    assert output_ptr[1] = 2;

    assert output_ptr[2] = 7;
    %{
            output_builtin.add_attribute('gps_fact_topology', [
                # Push 1 + n_pages pages (all of the pages).
                1, 
                # Create a parent node for the last n_pages.
                3,
                # Don't push additional pages.
                0,
                # Take the first page (the main part) and the node that was created (onchain data)
                # and use them to construct the root of the fact tree.
                2,
            ])
    %}
   
    // Return the updated output_ptr.
    return (output_ptr=&output_ptr[3]);
}
