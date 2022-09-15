const fs = require('fs');

const stats = JSON.parse(fs.readFileSync('stats.json', 'utf8'));
// const internal = JSON.parse(fs.readFileSync('fedex-stats.json', 'utf8'));




const styleBlock = `
<style>
        body {
            font-family: verdana;
        }
        .line-container {
            padding: 15px 10px;
            display: flex;
            flex-direction: column;
  
        }
        .line-container .subscription {
            height: 20px;
            display: flex;
            margin-top: 5px;
        }
        .line-container .subscription .segment-mdp {
            
            border-top: 1px black solid;
            border-bottom: 1px black solid;
            border-right: 0px black solid;
            background-color: aquamarine;
        }
        .line-container .subscription .segment-rp {
        
            border-top: 1px black solid;
            border-bottom: 1px black solid;
            border-right: 0px black solid;
            background-color: red;
        }

        .line-container .topic {
            display: flex;
            
        }
        .line-container .topic .ledger {
            height: 15px;
            background-color: blue;
            border-top: 1px white solid;
            border-bottom: 1px white solid;
            border-right: 1px white solid;            
        }
        .line-container .topic .ledger.first {
            background-color: blue;
            border-left: 1px white solid;            
        }
        .line-container .description {
            font-size: 12px;
        }
        .description-details {
            display: flex;
            flex-direction: column;
        }
        .description-details .detail-item {
            display: flex;
            
        }
        .description-details .detail-item span {
            font-size: 10px;
            padding: 2px;
        }
        .description-details .detail-item .detail-item-key {
            
            padding-right: 4px;
            font-weight: 400;
        }
        .description-details .detail-item .detail-item-value {
            font-weight: 900;

        }


        .tooltip {
            position: relative;
            display: inline-block;
            border-bottom: 1px dotted black;
        }
        .tooltip .tooltiptext {
            visibility: hidden;
            min-width: 30px;
            background-color: gold;
            border-radius: 2px;
            padding: 5px;
            margin: 12px;

            /* Position the tooltip */
            position: absolute;
            z-index: 1;
        }

        .tooltip:hover .tooltiptext {
             visibility: visible;
        }

    </style>`;



let html;

function generateSubLine(lineFill, ranges, all, totalEntries, details) {
    for (let r of ranges) {
        for (let i = r.from.entry; i < r.to.entry; i++) {
            if (!lineFill[r.from.ledger]) {
                lineFill[r.from.ledger] = {}
            }
            lineFill[r.from.ledger][i] = "ack" 
        }
    }

    
    let res = `<div class="subscription">`
    const singleEntryPercent = 100 / totalEntries
    let distanceFromTail = 0
    let currentType = "none"
    let currentN = 0
    for (const topicLedger of all) {
        for (let i = 0; i < topicLedger.entries; i++) {
            if (!lineFill[topicLedger.ledgerId]) {
                throw new Error("ledger " + topicLedger.ledgerId + " not in linefill")
            }
            const e = lineFill[topicLedger.ledgerId][i]
            if (currentType === "none") {
                currentType = e
            }
            if (e === currentType) {
                currentN++
                continue
            }
            if (currentType === "ack") {
                // res += `<div class="line segment-mdp tooltip" style="width: ${singleEntryPercent * currentN}%;"><span class="tooltiptext">${topicLedger.ledgerId}:${i}</span></div>`
                res += `<div class="line segment-mdp tooltip" style="width: ${singleEntryPercent * currentN}%;"></div>`
            } else {
                distanceFromTail += currentN
                // res += `<div class="line segment-rp tooltip " style="width: ${singleEntryPercent}%;"><span class="tooltiptext">${topicLedger.ledgerId}:${i}</span></div>`
                res += `<div class="line segment-rp tooltip" style="width: ${singleEntryPercent * currentN}%;"></div>`
            }
            currentType = e
            currentN = 1

        }
    }
    if (currentN > 0) {
        if (currentType === "ack") {
            // res += `<div class="line segment-mdp tooltip" style="width: ${singleEntryPercent * currentN}%;"><span class="tooltiptext">${topicLedger.ledgerId}:${i}</span></div>`
            res += `<div class="line segment-mdp tooltip" style="width: ${singleEntryPercent * currentN}%;"></div>`
        } else {
            distanceFromTail += currentN
            // res += `<div class="line segment-rp tooltip " style="width: ${singleEntryPercent}%;"><span class="tooltiptext">${topicLedger.ledgerId}:${i}</span></div>`
            res += `<div class="line segment-rp tooltip" style="width: ${singleEntryPercent * currentN}%;"></div>`
        }
    }
    res += "</div>"
    details.distanceFromTail = distanceFromTail
    return res
}

function generateSubDescription(mainDetails, details) {
    let result = `<div class="description">
    ${generateDetailsDescription(mainDetails)}
    <details>`;

    

    result += generateDetailsDescription(details)
    result += "</details></div>"
    return result
} 


function generateDetailsDescription(details) {
    let result = `<div class="description-details">`;
    for (const key in details) {
        result += `<div class="detail-item"><span class="detail-item-key">${key}</span><span class="detail-item-value">${details[key]}</span></div>`
    }
    result += "</div>"
    return result
} 

function generateLedgerSegment(ledger, isFirst, context, totalEntries) {
    const tooltip = generateDetailsDescription(ledger)
    const width = (100 / totalEntries) * ledger.entries
    context.mapping[ledger.ledgerId] = {}
    for (let i = 0; i < ledger.entries; i++) {
        context.mapping[ledger.ledgerId][i] = context.currentWidth++
    }
    
    return `<div class="ledger ${isFirst ? 'first' : ''} tooltip" style="width: ${width}%;"><span class="tooltiptext">${tooltip}</span></div>`
}
function createHtml() {
    html = `<html><head>${styleBlock}</head><body>`

    const context = {
        mapping: {},
        currentWidth: 0
    }
    html += `<div class="line-container"><div class="topic">`
    let firstLedger = true
    let totalEntries = 0
    const lastConfirmedEntryLedger = parseInt(internal.lastConfirmedEntry.split(":")[0])
    for (let ledger of internal.ledgers) {
        if (ledger.entries === 0 && ledger.ledgerId === lastConfirmedEntryLedger) {
            ledger.entries = parseInt(internal.lastConfirmedEntry.split(":")[1]) + 1
            console.log("filled ledger", ledger.ledgerId, ledger.entries)
        }
        totalEntries += ledger.entries
    }
    console.log(internal.ledgers)
    for (let ledger of internal.ledgers) {
        const ledgerSegment = generateLedgerSegment(ledger, firstLedger, context, totalEntries)
        html += `${ledgerSegment}`
        firstLedger = false
    }
    html += "</div></div>"

    for (const subName in internal.cursors) {

        sub = internal.cursors[subName]

        const details = {
            ...sub,
            properties: JSON.stringify(sub.properties)
        }
        // sub props

        const lineFill = {}
        

        

        const mdpLedger = parseInt(sub.markDeletePosition.split(":")[0])
        const mdpEntry = parseInt(sub.markDeletePosition.split(":")[1])
        for (let ledger of internal.ledgers) {
            lineFill[ledger.ledgerId] = {}
            
            if (mdpLedger > ledger.ledgerId) {
                for (let i = 0; i < ledger.entries; i++) {
                    lineFill[ledger.ledgerId][i] = "ack"
                }
            } else if (mdpLedger === ledger.ledgerId) {
                // ledger closed
                if (ledger.entries) {
                    for (let i = 0; i < mdpEntry + 1; i++) {
                        lineFill[ledger.ledgerId][i] = "ack"
                    }
                }
            } else {
                for (let i = 0; i < ledger.entries; i++) {
                    lineFill[ledger.ledgerId][i] = "rp"
                }
                continue
            }
        }

        const rpLedger = parseInt(sub.readPosition.split(":")[0])
        const rpEntry = parseInt(sub.readPosition.split(":")[1])
        for (let ledger of internal.ledgers) {
            if (rpLedger > ledger.ledgerId) {
                for (let i = 0; i < ledger.entries; i++) {
                    if (lineFill[ledger.ledgerId][i] !== "ack") {
                        lineFill[ledger.ledgerId][i] = "rp"
                    }
                }
            } else if (rpLedger === ledger.ledgerId) {
                // ledger closed
                if (ledger.entries) {
                    for (let i = 0; i < rpEntry - 1; i++) {
                        if (lineFill[ledger.ledgerId][i] !== "ack") {
                            lineFill[ledger.ledgerId][i] = "rp"
                        }   
                    }
                }
            } else {
                continue
            }
        }   

        for (let l in lineFill) {
            // console.log(subName, sub.markDeletePosition, "line", l, lineFill[l])
        }

        

        

        const line = generateSubLine(lineFill, parseRanges(sub.individuallyDeletedMessages), internal.ledgers, totalEntries, details)
        const description = generateSubDescription({subscription: subName, entriesFromTail: details.distanceFromTail}, details)
        html += `<div class="line-container">${description}${line}</div>`
    }


    

    return html
}

function parseRanges(string) {
    const result = []
    string = string.replaceAll("[", "").replaceAll("]", "").replaceAll("(", "").replaceAll(")", "")
    if (!string) {
        return result
    }

    const split = string.split(",")
    for (let s of split) {
        const range = s.split("..")
        const from = range[0]

        const fSplit = from.split(":")
        

        const to = range[1]
        const tSplit = to.split(":")

        const item = {
            from: {
                ledger: parseInt(fSplit[0]),
                entry: parseInt(fSplit[1])
            },
            to: {
                ledger: parseInt(tSplit[0]),
                entry: parseInt(tSplit[1])
            }
        }

        result.push(item)
    }
    return result
} 


fs.writeFileSync("output.html", createHtml())