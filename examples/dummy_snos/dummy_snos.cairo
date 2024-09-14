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

%builtins output pedersen range_check bitwise


from starkware.cairo.common.segments import relocate_segment
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.serialize import serialize_word

func main{output_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr}() -> () {
    alloc_locals;


    // assert output_ptr[0] = 1;
    // assert output_ptr[1] = 2;
    //
    // assert output_ptr[2] = 7;

    %{
            # onchain_data_start = ids.da_start
            # max_page_size=1
            # for i in range(4):
            #   start_offset = i * max_page_size
            #   output_builtin.add_page(
            #       page_id=1 + i,
            #       page_start=onchain_data_start + start_offset + 1,
            #       page_size=max_page_size
            #   )

            # Set the tree structure to a root with two children:
            # * A leaf which represents the main part
            # * An inner node for the onchain data part (which contains n_pages children).
            #
            # This is encoded using the following sequence:
            output_builtin.add_attribute('gps_fact_topology', [
                # Push 1 + n_pages pages (all of the pages).
                1 + 3,
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
    return ();
}
