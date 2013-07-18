#!/usr/bin/env python

def plot_data(data, results_dir, roi_name, colors, shapes):
    """
    plot_data does exactly what it says on the tin
    
    It calls plot_by_subs and plot_by_locs and saves these pictures
    as png files in the results_dir
    
    Inputs:     data (numpy rec array)
                results_dir
                roi_name
                colors
                shapes
    """
    #==========================================================================
    import numpy as np
    import os
    #==========================================================================
    
    # Get a list of the subjects:
    subs = [ sub for sub in data['sub'] ]
    subs = list(set(subs))
    sub_ids = [ np.int(sub) for sub in subs ]

    # List of locations
    locs = [ loc for loc in data['loc'] ]
    locs = list(set(locs))

    # List of location_ids
    loc_ids = [ loc_id for loc_id in data['loc_id'] ]
    loc_ids = list(set(loc_ids))
    loc_ids = [ np.int(loc_id) for loc_id in loc_ids ]
    
    output_name = os.path.join(results_dir, '{}_plot_by_subs.png'.format(roi_name))
    
    plot_by_subs(data=data, output_name=output_name,
                            colors=colors, shapes=shapes,
                            sub_ids=sub_ids, loc_ids=loc_ids, figsize=(15,5))
    
    output_name = os.path.join(results_dir, '{}_plot_by_locs.png'.format(roi_name))
    
    plot_by_locs(data=data, output_name=output_name,
                            colors=colors, shapes=shapes,
                            sub_ids= sub_ids, loc_ids=loc_ids, locs=locs, figsize=(15,5))

