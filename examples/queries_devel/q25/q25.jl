using HPAT

@acc hpat function q25(d_date, file_name)
    store_sales = DataSource(DataTable{:ss_customer_sk=Int64, :ss_ticket_number=Int64, :ss_sold_date_sk=Int64, :ss_net_paid=Float64}, HDF5, file_name)
    web_sales = DataSource(DataTable{:ws_bill_customer_sk=Int64, :ws_order_number=Int64, :ws_sold_date_sk=Int64, :ws_net_paid=Float64}, HDF5, file_name)

    store_sales = store_sales[:ss_sold_date_sk > d_date]
    web_sales   = web_sales[:ws_sold_date_sk > d_date]

    store_agg = aggregate(store_sales, :cid = :ss_customer_sk, 
                                           :frequency = count(union(:ss_ticket_number)),
                                           :most_recent_date = max(:ss_sold_date_sk),
                                           :amount = sum(:ss_net_paid))
    web_agg = aggregate(web_sales,  :cid = :ws_bill_customer_sk,
                                           :frequency = count(union(:ws_order_number)),
                                           :most_recent_date = max(:ws_sold_date_sk),
                                           :amount = sum(:ws_net_paid))
    web_store_agg = [store_agg; web_agg]

    result = aggregate(web_store_agg, :cid,
                                      :recency = (37621 - max(:most_recent_date) < 60 ? 1.0 : 0.0),
                                      :frequency = sum(:frequency),
                                      :totalspend = sum(:amount))
    return result[:cid], result[:recency], result[:frequency], result[:totalspend]

end

println(q25("33000", "test_q25.hdf5"))
