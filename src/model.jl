
"""
    create_node(m, n::Storage, 𝒯, 𝒫, modeltype::EnergyModel)

Set all constraints for a `Storage`. Can serve as fallback option for all unspecified
subtypes of `Storage`.
"""
function EMB.create_node(m, n::CO2Storage, 𝒯, 𝒫, modeltype::EnergyModel)

    p_stor = n.Stor_res
    # 𝒫ᵉᵐ    = EMB.res_sub(𝒫, ResourceEmit)
    𝒯ᴵⁿᵛ   = strategic_periods(𝒯)

    # Mass/energy balance constraints for stored energy carrier.
    for t_inv ∈ 𝒯ᴵⁿᵛ, t ∈ t_inv
        if t == first_operational(t_inv)
            if isfirst(t_inv)
                @constraint(m,
                    m[:stor_level][n, t] ==  (m[:flow_in][n, t , p_stor] -
                                            - m[:flow_out][n, t, p_stor]) * 
                                                duration(t)
                )
            else
                previous_operational = last_operational(previous(t_inv, 𝒯))
                @constraint(m,
                    m[:stor_level][n, t] ==  m[:stor_level][n, previous_operational] + 
                                                (m[:flow_in][n, t , p_stor] 
                                                - m[:flow_out][n, t, p_stor]) * 
                                                duration(t)
                )
            end
        else
            @constraint(m,
                m[:stor_level][n, t] ==  m[:stor_level][n, previous(t, 𝒯)] + 
                                            (m[:flow_in][n, t , p_stor] 
                                            - m[:flow_out][n, t, p_stor]) * 
                                            duration(t)
            )
        end
    end

    # Constraint for the other emissions to avoid problems with unconstrained variables.
    @constraint(m, [t ∈ 𝒯, p_em ∈ keys(n.Output)],
        m[:emissions_node][n, t, p_em] == 0)

    # The sink has no outputs.
    @constraint(m, [t ∈ 𝒯, p ∈ keys(n.Output)],
         m[:flow_out][n, t, p] == 0)

    # Constraint for storage rate use, and use of additional required input resources.
    EMB.constraints_flow_in(m, n, 𝒯)

    # Bounds for the storage level and storage rate used.
    EMB.constraints_capacity(m, n, 𝒯)

    EMB.constraints_opex_fixed(m, n, 𝒯ᴵⁿᵛ)
    EMB.constraints_opex_var(m, n, 𝒯ᴵⁿᵛ)

end
